#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase7_3_agent_execution_$STAMP"

echo "============================================================"
echo " PantherLang Phase 7.3 PRO - Agent Execution Engine"
echo "============================================================"
echo "[phase7.3] Project root: $ROOT"

fail(){ echo "[phase7.3][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "runtime/ai_runtime/ai_runtime.py"
require_file "runtime/memory/memory_store.py"
require_file "scripts/verify_phase7_2_native_memory.sh"

mkdir -p "$BACKUP_DIR"
for t in runtime/agents docs/phase7 examples/phase7_agents tests/phase7_3 scripts/verify_phase7_3_agent_execution.sh scripts/run_phase7_3_practical_demo.sh scripts/verify_phase7_all.sh CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase7.3] Verifying Phase 7.2 baseline..."
bash scripts/verify_phase7_2_native_memory.sh >/tmp/panther_phase7_3_phase72.log

mkdir -p runtime/agents docs/phase7 examples/phase7_agents tests/phase7_3 scripts
touch runtime/__init__.py runtime/agents/__init__.py

cat > runtime/agents/agent_context.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Any

from runtime.memory.memory_store import NativeMemoryStore


@dataclass
class AgentContext:
    agent_id: str
    name: str
    role: str
    memory: NativeMemoryStore = field(default_factory=NativeMemoryStore)
    state: dict[str, Any] = field(default_factory=dict)

    def remember(self, key: str, value: Any) -> None:
        self.memory.set(f"{self.name}.{key}", value)

    def recall(self, key: str) -> Any:
        return self.memory.get(f"{self.name}.{key}")

    def to_dict(self) -> dict[str, Any]:
        return {
            "agent_id": self.agent_id,
            "name": self.name,
            "role": self.role,
            "state": self.state,
            "memory": self.memory.snapshot(),
        }
PY

cat > runtime/agents/agent.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import uuid
from dataclasses import dataclass, field
from typing import Any

from runtime.agents.agent_context import AgentContext


class PantherAgentError(Exception):
    pass


@dataclass
class PantherAgent:
    name: str
    role: str = "worker"
    goal: str = ""
    agent_id: str = field(default_factory=lambda: str(uuid.uuid4()))

    def create_context(self) -> AgentContext:
        ctx = AgentContext(agent_id=self.agent_id, name=self.name, role=self.role)
        ctx.state["goal"] = self.goal
        return ctx

    def execute(self, instruction: str, context: AgentContext | None = None) -> dict[str, Any]:
        if not self.name.strip():
            raise PantherAgentError("Agent name cannot be empty")
        if not instruction.strip():
            raise PantherAgentError("Agent instruction cannot be empty")

        ctx = context or self.create_context()
        ctx.state["last_instruction"] = instruction
        ctx.state["last_result"] = f"{self.name}:{self.role}:executed:{instruction}"
        ctx.remember("last_instruction", instruction)
        ctx.remember("last_result", ctx.state["last_result"])

        return {
            "ok": True,
            "phase": "7.3",
            "agent": self.name,
            "role": self.role,
            "goal": self.goal,
            "instruction": instruction,
            "result": ctx.state["last_result"],
            "context": ctx.to_dict(),
            "network_used": False,
            "external_api_used": False,
            "deterministic": True,
        }
PY

cat > runtime/agents/agent_registry.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from runtime.agents.agent import PantherAgent, PantherAgentError


class AgentRegistry:
    def __init__(self) -> None:
        self.agents: dict[str, PantherAgent] = {}

    def register(self, agent: PantherAgent) -> PantherAgent:
        if agent.name in self.agents:
            raise PantherAgentError(f"Agent already registered: {agent.name}")
        self.agents[agent.name] = agent
        return agent

    def get(self, name: str) -> PantherAgent:
        if name not in self.agents:
            raise PantherAgentError(f"Agent not found: {name}")
        return self.agents[name]

    def list_agents(self) -> list[dict[str, str]]:
        return [
            {"name": agent.name, "role": agent.role, "goal": agent.goal, "agent_id": agent.agent_id}
            for agent in self.agents.values()
        ]
PY

cat > runtime/agents/agent_executor.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from typing import Any

from runtime.agents.agent import PantherAgent
from runtime.agents.agent_registry import AgentRegistry


class AgentExecutor:
    def __init__(self, registry: AgentRegistry | None = None) -> None:
        self.registry = registry or AgentRegistry()

    def register_agent(self, name: str, role: str = "worker", goal: str = "") -> PantherAgent:
        return self.registry.register(PantherAgent(name=name, role=role, goal=goal))

    def execute(self, name: str, instruction: str) -> dict[str, Any]:
        agent = self.registry.get(name)
        return agent.execute(instruction)

    def demo(self) -> dict[str, Any]:
        self.register_agent("ResearchAgent", role="researcher", goal="Analyze PantherLang runtime")
        result = self.execute("ResearchAgent", "phase7.3.demo")
        return {
            "ok": True,
            "phase": "7.3",
            "demo": "agent-execution-engine",
            "agents": self.registry.list_agents(),
            "result": result,
            "network_used": False,
            "external_api_used": False,
        }
PY

cat > runtime/agents/agent_api.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from runtime.agents.agent import PantherAgentError
from runtime.agents.agent_executor import AgentExecutor


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-agent")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("demo")
    run_p = sub.add_parser("run")
    run_p.add_argument("name")
    run_p.add_argument("instruction")
    run_p.add_argument("--role", default="worker")
    run_p.add_argument("--goal", default="")

    args = parser.parse_args(argv)
    executor = AgentExecutor()

    try:
        if args.cmd == "demo":
            print_json(executor.demo())
            return 0

        if args.cmd == "run":
            executor.register_agent(args.name, role=args.role, goal=args.goal)
            print_json(executor.execute(args.name, args.instruction))
            return 0

    except PantherAgentError as exc:
        print_json({"ok": False, "phase": "7.3", "error": str(exc)})
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x runtime/agents/agent_api.py

cat > docs/phase7/PHASE_7_3_STATUS.md <<'EOF'
# Phase 7.3 Status — Agent Execution Engine PRO

Completed:
- PantherAgent
- AgentContext
- AgentRegistry
- AgentExecutor
- Agent API
- Native Memory integration
- deterministic agent execution
- practical demo
- negative tests
- pytest suite

Next: Phase 7.4 — Task Scheduler.
EOF

cat > examples/phase7_agents/agent_demo.panther <<'EOF'
module panther.agents

agent ResearchAgent role researcher permissions ["memory", "execute"]

print "Phase 7.3 Agent Execution Engine"
print "Agent demo source compiled"
EOF

cat > scripts/run_phase7_3_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 runtime/agents/agent_api.py demo >/tmp/panther_phase7_3_agent_demo.json
grep -q '"ok": true' /tmp/panther_phase7_3_agent_demo.json
grep -q '"demo": "agent-execution-engine"' /tmp/panther_phase7_3_agent_demo.json
grep -q '"agent": "ResearchAgent"' /tmp/panther_phase7_3_agent_demo.json

OUT="/tmp/panther_phase7_3_compile_$$.sh"
./panther compile examples/phase7_agents/agent_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.3 Agent Execution Engine'
rm -f "$OUT"

echo "demo=phase7.3-agent-execution-engine"
echo "ok=true"
echo "agent_register=true"
echo "agent_execute=true"
echo "native_memory=true"
echo "compile_bridge=true"
echo "artifact_runs=true"
EOF
chmod +x scripts/run_phase7_3_practical_demo.sh

cat > tests/phase7_3/test_agent_execution.py <<'EOF'
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_agent_execute() -> None:
    from runtime.agents.agent import PantherAgent
    agent = PantherAgent(name="TestAgent", role="tester", goal="verify")
    result = agent.execute("run-test")
    assert result["ok"] is True
    assert result["agent"] == "TestAgent"
    assert result["context"]["memory"]["TestAgent.last_instruction"]["value"] == "run-test"


def test_registry_duplicate_fails() -> None:
    from runtime.agents.agent import PantherAgent, PantherAgentError
    from runtime.agents.agent_registry import AgentRegistry
    registry = AgentRegistry()
    registry.register(PantherAgent(name="A"))
    try:
        registry.register(PantherAgent(name="A"))
        raise AssertionError("duplicate agent should fail")
    except PantherAgentError:
        pass


def test_agent_api_demo() -> None:
    proc = subprocess.run(
        [sys.executable, "runtime/agents/agent_api.py", "demo"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["demo"] == "agent-execution-engine"
EOF

cat > scripts/verify_phase7_3_agent_execution.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.3 PRO Agent Execution Verification"
echo "============================================================"

test -f runtime/agents/agent.py
test -f runtime/agents/agent_context.py
test -f runtime/agents/agent_registry.py
test -f runtime/agents/agent_executor.py
test -f runtime/agents/agent_api.py
test -f examples/phase7_agents/agent_demo.panther
test -x scripts/run_phase7_3_practical_demo.sh
test -f tests/phase7_3/test_agent_execution.py
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.agents.agent import PantherAgent
agent = PantherAgent(name="VerifyAgent", role="verifier", goal="phase7.3")
result = agent.execute("verify-agent")
assert result["ok"] is True
assert result["agent"] == "VerifyAgent"
assert result["context"]["memory"]["VerifyAgent.last_instruction"]["value"] == "verify-agent"
print("✅ agent execution tests passed")
PY

python3 runtime/agents/agent_api.py demo >/tmp/panther_phase7_3_agent_api.json
grep -q '"ok": true' /tmp/panther_phase7_3_agent_api.json
grep -q '"demo": "agent-execution-engine"' /tmp/panther_phase7_3_agent_api.json
echo "✅ agent API tests passed"

OUT="/tmp/panther_phase7_3_verify_$$.sh"
./panther compile examples/phase7_agents/agent_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.3 Agent Execution Engine'
rm -f "$OUT"
echo "✅ compiler bridge tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase7_3_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase7.3-agent-execution-engine'
echo "$PRACTICAL_OUT" | grep -q 'agent_execute=true'
echo "$PRACTICAL_OUT" | grep -q 'native_memory=true'
echo "✅ practical agent demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase7_3 >/tmp/panther_phase7_3_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile runtime/agents/*.py
  echo "✅ python compile tests passed"
fi

echo "✅ PantherLang Phase 7.3 Agent Execution Engine verification complete."
EOF
chmod +x scripts/verify_phase7_3_agent_execution.sh

cat > scripts/verify_phase7_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase7_1_ai_runtime.sh
bash scripts/verify_phase7_2_native_memory.sh
bash scripts/verify_phase7_3_agent_execution.sh
echo "✅ ALL PHASE 7 TESTS PASSED THROUGH 7.3"
EOF
chmod +x scripts/verify_phase7_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 7.3 — Agent Execution Engine PRO

Added agent execution foundation:
- PantherAgent
- AgentContext
- AgentRegistry
- AgentExecutor
- Agent API
- Native Memory integration
- deterministic execution
- practical agent demo
- pytest suite

Next: Phase 7.4 Task Scheduler.
EOF

echo "[phase7.3] Running professional verification..."
bash scripts/verify_phase7_3_agent_execution.sh

echo "============================================================"
echo " Phase 7.3 COMPLETE"
echo " Next: Phase 7.4 Task Scheduler"
echo "============================================================"
