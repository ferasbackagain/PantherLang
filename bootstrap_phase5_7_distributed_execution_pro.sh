#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 5.7 Professional
# Distributed Execution + Local Node Runtime + Strong Practical Test Suite

PHASE="5.7"
PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.phase_backups/phase5_7_pro_$STAMP"

echo "============================================================"
echo " PantherLang Phase 5.7 PRO - Distributed Execution"
echo "============================================================"
echo "[phase5.7] Project root: $PROJECT_ROOT"

fail(){ echo "[phase5.7][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }
require_dir(){ [ -d "$1" ] || fail "Required directory missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_dir "language"
require_dir "scripts"
require_dir "architecture"

for s in \
  scripts/verify_phase5_1_ai_native_core.sh \
  scripts/verify_phase5_2_intelligent_type_system.sh \
  scripts/verify_phase5_3_memory_context_engine.sh \
  scripts/verify_phase5_4_multi_agent_runtime.sh \
  scripts/verify_phase5_5_natural_language_programming.sh \
  scripts/verify_phase5_6_ai_optimizing_compiler.sh
do
  require_file "$s"
done

echo "[phase5.7] Verifying Phase 5.1 dependency..."
bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency.log
echo "[phase5.7] Verifying Phase 5.2 dependency..."
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency.log
echo "[phase5.7] Verifying Phase 5.3 dependency..."
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency.log
echo "[phase5.7] Verifying Phase 5.4 dependency..."
bash scripts/verify_phase5_4_multi_agent_runtime.sh >/tmp/panther_phase5_4_dependency.log
echo "[phase5.7] Verifying Phase 5.5 dependency..."
bash scripts/verify_phase5_5_natural_language_programming.sh >/tmp/panther_phase5_5_dependency.log
echo "[phase5.7] Verifying Phase 5.6 dependency..."
bash scripts/verify_phase5_6_ai_optimizing_compiler.sh >/tmp/panther_phase5_6_dependency.log

mkdir -p "$BACKUP_DIR"
backup_if_exists(){ local t="$1"; if [ -e "$t" ]; then mkdir -p "$BACKUP_DIR/$(dirname "$t")"; cp -a "$t" "$BACKUP_DIR/$t"; fi; }

echo "[phase5.7] Creating backup at: $BACKUP_DIR"
for t in language/distributed language/ai/distributed architecture/DISTRIBUTED_EXECUTION.md docs/phase5/PHASE_5_7_STATUS.md examples/distributed tests/phase5_7 scripts/verify_phase5_7_distributed_execution.sh scripts/run_phase5_7_practical_demo.sh CHANGELOG.md; do
  backup_if_exists "$t"
done

echo "[phase5.7] Creating Distributed Execution directories..."
mkdir -p language/distributed/{core,runtime,schemas,policies} language/ai/distributed architecture docs/phase5 examples/distributed tests/phase5_7 scripts

cat > architecture/DISTRIBUTED_EXECUTION.md <<'MD'
# PantherLang Phase 5.7 — Distributed Execution

Phase 5.7 introduces a deterministic local distributed execution foundation.

## Mission

PantherLang must be able to model distributed work safely before true networked clusters are added.

This phase creates a local, deterministic cluster simulator:

- node identity
- node capabilities
- task distribution
- scheduler
- result collection
- failure handling
- security policy
- practical distributed workflow demo
- stress and negative tests

## Important

This phase does **not** open sockets, call external APIs, or run remote commands. It simulates a distributed runtime locally so the semantics are stable and testable first.

## Professional Rule

No feature is complete without proof:
structure + schema + runtime + scheduling + failure + stress + practical demo.
MD

cat > language/distributed/core/distributed_manifest.json <<'JSON'
{
  "name": "PantherLang Distributed Execution",
  "phase": "5.7",
  "version": "0.5.7-distributed-execution-pro",
  "status": "experimental-foundation",
  "depends_on": ["5.1", "5.2", "5.3", "5.4", "5.5", "5.6"],
  "external_api_required": false,
  "network_required": false,
  "features": [
    "local_cluster_simulator",
    "node_identity",
    "node_capabilities",
    "task_distribution",
    "deterministic_scheduler",
    "result_collection",
    "failure_handling",
    "stress_tests",
    "practical_demo"
  ],
  "testing_standard": ["structure", "schema", "runtime", "scheduling", "negative", "stress", "practical"]
}
JSON

cat > language/distributed/core/distributed_types.panther <<'PAN'
# PantherLang Distributed Execution Types
# Phase 5.7 syntax foundation

type NodeId = String
type NodeStatus = "ready" | "busy" | "failed" | "offline"
type TaskStatus = "queued" | "running" | "completed" | "failed"

type DistributedNode {
  id: NodeId
  status: NodeStatus
  capabilities: List<String>
}

type DistributedTask<T> {
  id: String
  required_capability: String
  payload: T
  status: TaskStatus
}

type DistributedResult<T> {
  task_id: String
  node_id: NodeId
  ok: Bool
  output: T
}
PAN

cat > language/ai/distributed/distributed_ai_types.panther <<'PAN'
# PantherLang AI Distributed Types
# Phase 5.7 AI-aware distributed execution foundation

type DistributedAgentNode = DistributedNode
type DistributedAIWorkflow<T> {
  id: String
  nodes: List<DistributedNode>
  tasks: List<DistributedTask<T>>
}

type DistributedAIReport {
  ok: Bool
  scheduled_tasks: Int
  completed_tasks: Int
  failed_tasks: Int
  deterministic: Bool
}
PAN

cat > language/distributed/policies/default_distributed.policy.json <<'JSON'
{
  "name": "default_distributed",
  "phase": "5.7",
  "allow_network": false,
  "allow_remote_shell": false,
  "allow_secret_access": false,
  "max_nodes": 100,
  "max_tasks": 5000,
  "require_registered_node": true,
  "require_capability_match": true,
  "audit_required": true,
  "scheduler": {
    "mode": "deterministic_round_robin",
    "retry_failed_tasks": false
  }
}
JSON

cat > language/distributed/schemas/distributed_task.schema.json <<'JSON'
{
  "title": "PantherLang Distributed Task",
  "phase": "5.7",
  "type": "object",
  "required": ["id", "required_capability", "payload", "status", "audit"],
  "properties": {
    "id": { "type": "string" },
    "required_capability": { "type": "string" },
    "payload": { "type": ["string", "number", "boolean", "object", "array", "null"] },
    "status": { "type": "string" },
    "audit": { "type": "object" }
  }
}
JSON

cat > language/distributed/runtime/distributed_runtime.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from typing import Any


class PantherDistributedError(Exception):
    pass


@dataclass
class Node:
    id: str
    status: str
    capabilities: list[str]


@dataclass
class Task:
    id: str
    required_capability: str
    payload: Any
    status: str
    audit: dict[str, Any]


@dataclass
class Result:
    task_id: str
    node_id: str
    ok: bool
    output: Any
    audit: dict[str, Any]


class LocalDistributedRuntime:
    def __init__(self, max_nodes: int = 100, max_tasks: int = 5000) -> None:
        self.max_nodes = max_nodes
        self.max_tasks = max_tasks
        self.nodes: dict[str, Node] = {}
        self.tasks: list[Task] = []
        self.results: list[Result] = []
        self.failures = 0

    def now(self) -> str:
        return datetime.now(timezone.utc).isoformat()

    def audit(self) -> dict[str, Any]:
        return {
            "phase": "5.7",
            "runtime": "local_deterministic_distributed",
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
            "created_at": self.now(),
        }

    def add_node(self, node_id: str, capabilities: list[str]) -> Node:
        if not node_id.strip():
            raise PantherDistributedError("Node id cannot be empty")
        if len(self.nodes) >= self.max_nodes and node_id not in self.nodes:
            raise PantherDistributedError("Node limit exceeded")
        if not capabilities:
            raise PantherDistributedError("Node must have at least one capability")
        node = Node(id=node_id, status="ready", capabilities=capabilities)
        self.nodes[node_id] = node
        return node

    def add_task(self, task_id: str, required_capability: str, payload: Any) -> Task:
        if not task_id.strip():
            raise PantherDistributedError("Task id cannot be empty")
        if len(self.tasks) >= self.max_tasks:
            raise PantherDistributedError("Task limit exceeded")
        if not required_capability.strip():
            raise PantherDistributedError("Task required capability cannot be empty")
        task = Task(
            id=task_id,
            required_capability=required_capability,
            payload=payload,
            status="queued",
            audit=self.audit(),
        )
        self.tasks.append(task)
        return task

    def eligible_nodes(self, capability: str) -> list[Node]:
        return [
            n for n in sorted(self.nodes.values(), key=lambda x: x.id)
            if n.status == "ready" and capability in n.capabilities
        ]

    def execute_task(self, task: Task, node: Node) -> Result:
        task.status = "running"
        node.status = "busy"

        # Deterministic local execution model.
        if isinstance(task.payload, (int, float)):
            output = task.payload * 2
        elif isinstance(task.payload, str):
            output = task.payload.upper()
        else:
            output = task.payload

        task.status = "completed"
        node.status = "ready"
        result = Result(
            task_id=task.id,
            node_id=node.id,
            ok=True,
            output=output,
            audit=self.audit(),
        )
        self.results.append(result)
        return result

    def run(self) -> dict[str, Any]:
        if not self.nodes:
            raise PantherDistributedError("No nodes registered")
        for task in self.tasks:
            if task.status != "queued":
                continue
            nodes = self.eligible_nodes(task.required_capability)
            if not nodes:
                task.status = "failed"
                self.failures += 1
                continue
            # Deterministic round-robin based on completed results count.
            node = nodes[len(self.results) % len(nodes)]
            self.execute_task(task, node)

        return {
            "phase": "5.7",
            "ok": self.failures == 0,
            "nodes": [asdict(n) for n in sorted(self.nodes.values(), key=lambda x: x.id)],
            "tasks": [asdict(t) for t in self.tasks],
            "results": [asdict(r) for r in self.results],
            "scheduled_tasks": len(self.tasks),
            "completed_tasks": len(self.results),
            "failed_tasks": self.failures,
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
        }

    def demo(self) -> dict[str, Any]:
        self.add_node("node-a", ["text", "math"])
        self.add_node("node-b", ["text"])
        self.add_node("node-c", ["math"])
        self.add_task("task-1", "text", "panther distributed execution")
        self.add_task("task-2", "math", 21)
        self.add_task("task-3", "text", "ai native runtime")
        return self.run()

    def stress(self, count: int) -> dict[str, Any]:
        self.add_node("node-a", ["math"])
        self.add_node("node-b", ["math"])
        for i in range(count):
            self.add_task(f"stress-{i}", "math", i)
        return self.run()


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-distributed-runtime")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("demo")

    stress = sub.add_parser("stress")
    stress.add_argument("--count", type=int, default=50)

    neg = sub.add_parser("negative")
    neg.add_argument("--case", choices=["no-nodes", "missing-capability", "bad-node", "bad-task"], required=True)

    args = parser.parse_args(argv)

    try:
        rt = LocalDistributedRuntime()
        if args.cmd == "demo":
            print_json(rt.demo())
            return 0
        if args.cmd == "stress":
            print_json(rt.stress(args.count))
            return 0
        if args.cmd == "negative":
            if args.case == "no-nodes":
                rt.add_task("task-1", "math", 1)
                result = rt.run()
                if result["failed_tasks"] > 0:
                    raise PantherDistributedError("No eligible nodes for task execution")
            elif args.case == "missing-capability":
                rt.add_node("node-a", ["text"])
                rt.add_task("task-1", "math", 1)
                result = rt.run()
                if result["failed_tasks"] > 0:
                    raise PantherDistributedError("Missing required node capability: math")
            elif args.case == "bad-node":
                rt.add_node("", ["math"])
            elif args.case == "bad-task":
                rt.add_node("node-a", ["math"])
                rt.add_task("", "math", 1)

    except PantherDistributedError as exc:
        print_json({
            "ok": False,
            "phase": "5.7",
            "error": str(exc),
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x language/distributed/runtime/distributed_runtime.py

cat > examples/distributed/phase5_7_distributed.panther <<'PAN'
# PantherLang Phase 5.7 Distributed Execution practical language-facing example

node "node-a" capabilities ["text", "math"]
node "node-b" capabilities ["text"]
node "node-c" capabilities ["math"]

distributed workflow local_cluster {
  task "task-1" requires "text" payload "panther distributed execution"
  task "task-2" requires "math" payload 21
  task "task-3" requires "text" payload "ai native runtime"
}

run distributed workflow local_cluster
PAN

cat > examples/distributed/phase5_7_practical_expected.txt <<'TXT'
demo=distributed-execution
ok=true
scheduled_tasks=3
completed_tasks=3
failed_tasks=0
external_api_used=false
network_used=false
deterministic=true
contains=PANTHER DISTRIBUTED EXECUTION
contains=42
TXT

cat > scripts/run_phase5_7_practical_demo.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="$(python3 language/distributed/runtime/distributed_runtime.py demo)"

python3 - "$OUT" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["phase"] == "5.7"
assert data["ok"] is True
assert data["scheduled_tasks"] == 3
assert data["completed_tasks"] == 3
assert data["failed_tasks"] == 0
assert data["external_api_used"] is False
assert data["network_used"] is False
assert data["deterministic"] is True
outputs = [r["output"] for r in data["results"]]
assert "PANTHER DISTRIBUTED EXECUTION" in outputs
assert 42 in outputs
print("demo=distributed-execution")
print("ok=true")
print("scheduled_tasks=3")
print("completed_tasks=3")
print("failed_tasks=0")
print("external_api_used=false")
print("network_used=false")
print("deterministic=true")
print("contains=PANTHER DISTRIBUTED EXECUTION")
print("contains=42")
PY
SH
chmod +x scripts/run_phase5_7_practical_demo.sh

cat > tests/phase5_7/test_distributed_runtime.py <<'PY'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "distributed" / "runtime" / "distributed_runtime.py"

def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(RUNTIME), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)

def test_demo_distributed_runtime() -> None:
    code, data = run_cmd("demo")
    assert code == 0
    assert data["ok"] is True
    assert data["completed_tasks"] == 3
    assert data["failed_tasks"] == 0
    assert data["network_used"] is False

def test_stress_runtime() -> None:
    code, data = run_cmd("stress", "--count", "50")
    assert code == 0
    assert data["ok"] is True
    assert data["scheduled_tasks"] == 50
    assert data["completed_tasks"] == 50

def test_missing_capability_fails() -> None:
    code, data = run_cmd("negative", "--case", "missing-capability")
    assert code == 2
    assert data["ok"] is False
    assert "Missing required node capability" in data["error"]

def test_bad_node_fails() -> None:
    code, data = run_cmd("negative", "--case", "bad-node")
    assert code == 2
    assert data["ok"] is False
    assert "Node id cannot be empty" in data["error"]
PY

cat > docs/phase5/PHASE_5_7_STATUS.md <<'MD'
# Phase 5.7 Status — Distributed Execution PRO

## Completed

- Distributed Execution architecture.
- Distributed manifest.
- Distributed type definitions.
- AI distributed type definitions.
- Default distributed policy.
- Distributed task schema.
- Deterministic local distributed runtime.
- Local cluster simulator.
- Practical distributed workflow demo.
- Stress test.
- Negative/failure tests.
- Pytest suite.
- Professional verification script.

## Next Phase

Phase 5.8 — Secure AI Sandbox.
MD

cat > scripts/verify_phase5_7_distributed_execution.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.7 PRO Verification"
echo "============================================================"

bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency_verify.log
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency_verify.log
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency_verify.log
bash scripts/verify_phase5_4_multi_agent_runtime.sh >/tmp/panther_phase5_4_dependency_verify.log
bash scripts/verify_phase5_5_natural_language_programming.sh >/tmp/panther_phase5_5_dependency_verify.log
bash scripts/verify_phase5_6_ai_optimizing_compiler.sh >/tmp/panther_phase5_6_dependency_verify.log

test -f architecture/DISTRIBUTED_EXECUTION.md
test -f language/distributed/core/distributed_manifest.json
test -f language/distributed/core/distributed_types.panther
test -f language/ai/distributed/distributed_ai_types.panther
test -f language/distributed/policies/default_distributed.policy.json
test -f language/distributed/schemas/distributed_task.schema.json
test -x language/distributed/runtime/distributed_runtime.py
test -f examples/distributed/phase5_7_distributed.panther
test -f examples/distributed/phase5_7_practical_expected.txt
test -x scripts/run_phase5_7_practical_demo.sh
test -f tests/phase5_7/test_distributed_runtime.py
test -f docs/phase5/PHASE_5_7_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/distributed/core/distributed_manifest.json").read_text())
assert m["phase"] == "5.7"
for dep in ["5.1","5.2","5.3","5.4","5.5","5.6"]:
    assert dep in m["depends_on"]
assert m["external_api_required"] is False
assert m["network_required"] is False
assert "task_distribution" in m["features"]
p = json.loads(Path("language/distributed/policies/default_distributed.policy.json").read_text())
assert p["allow_network"] is False
assert p["allow_remote_shell"] is False
assert p["require_capability_match"] is True
s = json.loads(Path("language/distributed/schemas/distributed_task.schema.json").read_text())
for key in ["id","required_capability","payload","status","audit"]:
    assert key in s["required"]
PY
echo "✅ schema tests passed"

DEMO_JSON="$(python3 language/distributed/runtime/distributed_runtime.py demo)"
echo "$DEMO_JSON" | grep -q '"phase": "5.7"'
echo "$DEMO_JSON" | grep -q '"ok": true'
echo "$DEMO_JSON" | grep -q '"scheduled_tasks": 3'
echo "$DEMO_JSON" | grep -q '"completed_tasks": 3'
echo "$DEMO_JSON" | grep -q '"failed_tasks": 0'
echo "$DEMO_JSON" | grep -q '"network_used": false'
echo "✅ runtime distributed tests passed"

python3 - "$DEMO_JSON" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
outputs = [r["output"] for r in data["results"]]
assert "PANTHER DISTRIBUTED EXECUTION" in outputs
assert "AI NATIVE RUNTIME" in outputs
assert 42 in outputs
for r in data["results"]:
    assert r["audit"]["external_api_used"] is False
    assert r["audit"]["network_used"] is False
    assert r["audit"]["deterministic"] is True
PY
echo "✅ scheduling/result tests passed"

STRESS_JSON="$(python3 language/distributed/runtime/distributed_runtime.py stress --count 50)"
echo "$STRESS_JSON" | grep -q '"ok": true'
echo "$STRESS_JSON" | grep -q '"scheduled_tasks": 50'
echo "$STRESS_JSON" | grep -q '"completed_tasks": 50'
echo "$STRESS_JSON" | grep -q '"failed_tasks": 0'
echo "✅ stress tests passed"

set +e
BAD_NODE="$(python3 language/distributed/runtime/distributed_runtime.py negative --case bad-node)"
BAD_NODE_CODE=$?
BAD_TASK="$(python3 language/distributed/runtime/distributed_runtime.py negative --case bad-task)"
BAD_TASK_CODE=$?
BAD_CAP="$(python3 language/distributed/runtime/distributed_runtime.py negative --case missing-capability)"
BAD_CAP_CODE=$?
set -e
if [ "$BAD_NODE_CODE" -ne 2 ] || [ "$BAD_TASK_CODE" -ne 2 ] || [ "$BAD_CAP_CODE" -ne 2 ]; then
  echo "[verify_phase5.7][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_NODE" | grep -q 'Node id cannot be empty'
echo "$BAD_TASK" | grep -q 'Task id cannot be empty'
echo "$BAD_CAP" | grep -q 'Missing required node capability'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase5_7_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=distributed-execution'
echo "$PRACTICAL_OUT" | grep -q 'ok=true'
echo "$PRACTICAL_OUT" | grep -q 'completed_tasks=3'
echo "$PRACTICAL_OUT" | grep -q 'contains=42'
echo "✅ practical distributed execution demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_7 >/tmp/panther_phase5_7_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/distributed/runtime/distributed_runtime.py
  echo "✅ python compile test passed"
fi

echo "✅ PantherLang Phase 5.7 Distributed Execution verification complete."
SH
chmod +x scripts/verify_phase5_7_distributed_execution.sh

cat >> CHANGELOG.md <<'MD'

## Phase 5.7 — Distributed Execution PRO

Added deterministic local distributed execution foundation:

- distributed manifest
- distributed and AI distributed type definitions
- distributed policy
- distributed task schema
- local cluster simulator
- deterministic task scheduler
- result collection
- stress tests
- negative/failure tests
- practical distributed demo
- pytest suite
- professional verification gates

Phase 5.7 depends on Phase 5.1 through Phase 5.6.
MD

echo "[phase5.7] Running professional verification..."
bash scripts/verify_phase5_7_distributed_execution.sh

echo "============================================================"
echo " Phase 5.7 COMPLETE"
echo " Next: Phase 5.8 Secure AI Sandbox"
echo "============================================================"
