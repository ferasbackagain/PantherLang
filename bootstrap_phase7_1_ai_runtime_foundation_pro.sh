#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase7_1_ai_runtime_$STAMP"

echo "============================================================"
echo " PantherLang Phase 7.1 PRO - AI Runtime Foundation"
echo "============================================================"
echo "[phase7.1] Project root: $ROOT"

fail(){ echo "[phase7.1][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "compiler/pipeline/panther_compiler.py"
require_file "scripts/verify_phase6_20_production_readiness.sh"

mkdir -p "$BACKUP_DIR"
for t in runtime/ai_runtime docs/phase7 examples/phase7_runtime tests/phase7_1 scripts/verify_phase7_1_ai_runtime.sh scripts/run_phase7_1_practical_demo.sh scripts/verify_phase7_all.sh CHANGELOG.md panther; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase7.1] Verifying Phase 6.20 baseline..."
bash scripts/verify_phase6_20_production_readiness.sh >/tmp/panther_phase7_1_phase620.log

mkdir -p runtime/ai_runtime docs/phase7 examples/phase7_runtime tests/phase7_1 scripts
touch runtime/__init__.py runtime/ai_runtime/__init__.py

cat > runtime/ai_runtime/runtime_config.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Any


@dataclass
class RuntimeConfig:
    runtime_name: str = "Panther AI Runtime"
    phase: str = "7.1"
    deterministic: bool = True
    network_enabled: bool = False
    external_api_enabled: bool = False
    max_events: int = 1000

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
PY

cat > runtime/ai_runtime/runtime_events.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, asdict
from time import time
from typing import Any


@dataclass
class RuntimeEvent:
    name: str
    payload: dict[str, Any]
    timestamp: float

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


class RuntimeEventBus:
    def __init__(self, max_events: int = 1000) -> None:
        self.max_events = max_events
        self.events: list[RuntimeEvent] = []

    def emit(self, name: str, payload: dict[str, Any] | None = None) -> RuntimeEvent:
        event = RuntimeEvent(name=name, payload=payload or {}, timestamp=time())
        self.events.append(event)
        if len(self.events) > self.max_events:
            self.events = self.events[-self.max_events:]
        return event

    def list_events(self) -> list[dict[str, Any]]:
        return [event.to_dict() for event in self.events]
PY

cat > runtime/ai_runtime/runtime_context.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Any


@dataclass
class RuntimeContext:
    session_id: str
    state: str = "created"
    memory: dict[str, Any] = field(default_factory=dict)

    def set(self, key: str, value: Any) -> None:
        self.memory[key] = value

    def get(self, key: str, default: Any = None) -> Any:
        return self.memory.get(key, default)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
PY

cat > runtime/ai_runtime/runtime_session.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import uuid
from dataclasses import dataclass, asdict
from typing import Any

from runtime.ai_runtime.runtime_context import RuntimeContext


@dataclass
class RuntimeSession:
    session_id: str
    context: RuntimeContext

    def to_dict(self) -> dict[str, Any]:
        return {
            "session_id": self.session_id,
            "context": self.context.to_dict()
        }


class RuntimeSessionManager:
    def __init__(self) -> None:
        self.sessions: dict[str, RuntimeSession] = {}

    def create_session(self) -> RuntimeSession:
        sid = str(uuid.uuid4())
        session = RuntimeSession(session_id=sid, context=RuntimeContext(session_id=sid))
        self.sessions[sid] = session
        return session

    def get_session(self, session_id: str) -> RuntimeSession:
        if session_id not in self.sessions:
            raise KeyError(f"Runtime session not found: {session_id}")
        return self.sessions[session_id]
PY

cat > runtime/ai_runtime/ai_runtime.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import asdict
from typing import Any

from runtime.ai_runtime.runtime_config import RuntimeConfig
from runtime.ai_runtime.runtime_events import RuntimeEventBus
from runtime.ai_runtime.runtime_session import RuntimeSessionManager, RuntimeSession


class PantherAIRuntimeError(Exception):
    pass


class PantherAIRuntime:
    def __init__(self, config: RuntimeConfig | None = None) -> None:
        self.config = config or RuntimeConfig()
        self.events = RuntimeEventBus(max_events=self.config.max_events)
        self.sessions = RuntimeSessionManager()
        self.started = False
        self.active_session: RuntimeSession | None = None

    def initialize(self) -> dict[str, Any]:
        if self.started:
            raise PantherAIRuntimeError("Runtime already started")
        self.started = True
        self.active_session = self.sessions.create_session()
        self.active_session.context.state = "running"
        self.events.emit("runtime.initialized", {"session_id": self.active_session.session_id})
        return self.status()

    def execute(self, instruction: str) -> dict[str, Any]:
        if not self.started or self.active_session is None:
            raise PantherAIRuntimeError("Runtime must be initialized before execute")
        if not instruction.strip():
            raise PantherAIRuntimeError("Instruction cannot be empty")

        self.events.emit("runtime.execute", {"instruction": instruction})
        self.active_session.context.set("last_instruction", instruction)
        self.active_session.context.set("last_result", f"executed:{instruction}")

        return {
            "ok": True,
            "phase": "7.1",
            "instruction": instruction,
            "result": f"executed:{instruction}",
            "deterministic": self.config.deterministic,
            "network_used": False,
            "external_api_used": False,
        }

    def shutdown(self) -> dict[str, Any]:
        if not self.started:
            raise PantherAIRuntimeError("Runtime is not started")
        if self.active_session:
            self.active_session.context.state = "stopped"
        self.events.emit("runtime.shutdown", {})
        self.started = False
        return self.status()

    def status(self) -> dict[str, Any]:
        return {
            "ok": True,
            "phase": "7.1",
            "runtime": self.config.to_dict(),
            "started": self.started,
            "active_session": self.active_session.to_dict() if self.active_session else None,
            "events": self.events.list_events(),
            "network_used": False,
            "external_api_used": False,
        }
PY

cat > runtime/ai_runtime/runtime_api.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from typing import Any

from runtime.ai_runtime.ai_runtime import PantherAIRuntime, PantherAIRuntimeError


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-runtime")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("start")
    exec_p = sub.add_parser("execute")
    exec_p.add_argument("instruction")
    sub.add_parser("demo")
    sub.add_parser("status")

    args = parser.parse_args(argv)

    try:
        runtime = PantherAIRuntime()

        if args.cmd == "start":
            print_json(runtime.initialize())
            return 0

        if args.cmd == "execute":
            runtime.initialize()
            print_json(runtime.execute(args.instruction))
            runtime.shutdown()
            return 0

        if args.cmd == "demo":
            runtime.initialize()
            result = runtime.execute("phase7.1.demo")
            status = runtime.shutdown()
            print_json({
                "ok": True,
                "phase": "7.1",
                "demo": "ai-runtime-foundation",
                "execute_result": result,
                "shutdown_status": status,
                "network_used": False,
                "external_api_used": False,
            })
            return 0

        if args.cmd == "status":
            print_json(runtime.status())
            return 0

    except PantherAIRuntimeError as exc:
        print_json({
            "ok": False,
            "phase": "7.1",
            "error": str(exc),
            "network_used": False,
            "external_api_used": False,
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x runtime/ai_runtime/runtime_api.py

cat > docs/phase7/PHASE_7_1_STATUS.md <<'EOF'
# Phase 7.1 Status — AI Runtime Foundation PRO

Completed:
- AI Runtime Core
- Runtime Config
- Runtime Context
- Runtime Session Manager
- Runtime Event Bus
- Runtime API
- CLI integration foundation
- practical demo
- negative tests
- pytest suite

Next: Phase 7.2 — Native Memory Model.
EOF

cat > examples/phase7_runtime/runtime_demo.panther <<'EOF'
module panther.runtime

print "Phase 7.1 AI Runtime Foundation"
print "Runtime demo source compiled"
EOF

cat > scripts/run_phase7_1_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 runtime/ai_runtime/runtime_api.py demo >/tmp/panther_phase7_1_runtime_demo.json
grep -q '"ok": true' /tmp/panther_phase7_1_runtime_demo.json
grep -q '"demo": "ai-runtime-foundation"' /tmp/panther_phase7_1_runtime_demo.json

OUT="/tmp/panther_phase7_1_compile_$$.sh"
./panther compile examples/phase7_runtime/runtime_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.1 AI Runtime Foundation'
rm -f "$OUT"

echo "demo=phase7.1-ai-runtime-foundation"
echo "ok=true"
echo "runtime_start=true"
echo "runtime_execute=true"
echo "runtime_shutdown=true"
echo "compile_bridge=true"
echo "artifact_runs=true"
EOF
chmod +x scripts/run_phase7_1_practical_demo.sh

cat > tests/phase7_1/test_ai_runtime.py <<'EOF'
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_runtime_lifecycle() -> None:
    from runtime.ai_runtime.ai_runtime import PantherAIRuntime
    runtime = PantherAIRuntime()
    status = runtime.initialize()
    assert status["started"] is True
    result = runtime.execute("test")
    assert result["ok"] is True
    assert result["result"] == "executed:test"
    stopped = runtime.shutdown()
    assert stopped["started"] is False


def test_runtime_empty_instruction_fails() -> None:
    from runtime.ai_runtime.ai_runtime import PantherAIRuntime, PantherAIRuntimeError
    runtime = PantherAIRuntime()
    runtime.initialize()
    try:
        runtime.execute("")
        raise AssertionError("empty instruction should fail")
    except PantherAIRuntimeError:
        pass


def test_runtime_api_demo() -> None:
    proc = subprocess.run(
        [sys.executable, "runtime/ai_runtime/runtime_api.py", "demo"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["demo"] == "ai-runtime-foundation"
EOF

cat > scripts/verify_phase7_1_ai_runtime.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.1 PRO AI Runtime Verification"
echo "============================================================"

test -f runtime/ai_runtime/ai_runtime.py
test -f runtime/ai_runtime/runtime_config.py
test -f runtime/ai_runtime/runtime_context.py
test -f runtime/ai_runtime/runtime_session.py
test -f runtime/ai_runtime/runtime_events.py
test -f runtime/ai_runtime/runtime_api.py
test -f examples/phase7_runtime/runtime_demo.panther
test -x scripts/run_phase7_1_practical_demo.sh
test -f tests/phase7_1/test_ai_runtime.py
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.ai_runtime.ai_runtime import PantherAIRuntime, PantherAIRuntimeError

runtime = PantherAIRuntime()
status = runtime.initialize()
assert status["started"] is True
result = runtime.execute("verify")
assert result["ok"] is True
assert result["result"] == "executed:verify"
shutdown = runtime.shutdown()
assert shutdown["started"] is False
print("✅ runtime lifecycle tests passed")
PY

python3 runtime/ai_runtime/runtime_api.py demo >/tmp/panther_phase7_1_api_demo.json
grep -q '"ok": true' /tmp/panther_phase7_1_api_demo.json
grep -q '"demo": "ai-runtime-foundation"' /tmp/panther_phase7_1_api_demo.json
echo "✅ runtime API tests passed"

OUT="/tmp/panther_phase7_1_verify_$$.sh"
./panther compile examples/phase7_runtime/runtime_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.1 AI Runtime Foundation'
rm -f "$OUT"
echo "✅ compiler bridge tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase7_1_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase7.1-ai-runtime-foundation'
echo "$PRACTICAL_OUT" | grep -q 'runtime_execute=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical AI runtime demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase7_1 >/tmp/panther_phase7_1_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile runtime/ai_runtime/*.py
  echo "✅ python compile tests passed"
fi

echo "✅ PantherLang Phase 7.1 AI Runtime Foundation verification complete."
EOF
chmod +x scripts/verify_phase7_1_ai_runtime.sh

# Add runtime command to panther CLI if not present.
if ! grep -q "runtime/ai_runtime/runtime_api.py" panther; then
  cp panther "$BACKUP_DIR/panther.before_phase7_1"
  python3 - <<'PY'
from pathlib import Path
p = Path("panther")
txt = p.read_text()
needle = 'case "${1:-}" in\n'
if needle not in txt:
    raise SystemExit("panther CLI case block not found")
insert = '''  runtime)
    shift
    python3 "$ROOT/runtime/ai_runtime/runtime_api.py" "$@"
    ;;

'''
txt = txt.replace(needle, needle + insert)
p.write_text(txt)
PY
  chmod +x panther
fi

cat > scripts/verify_phase7_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase7_1_ai_runtime.sh
echo "✅ ALL PHASE 7 TESTS PASSED THROUGH 7.1"
EOF
chmod +x scripts/verify_phase7_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 7.1 — AI Runtime Foundation PRO

Added AI Runtime foundation:
- runtime lifecycle
- runtime config
- runtime context
- runtime sessions
- runtime events
- runtime API
- CLI runtime command foundation
- practical runtime demo
- pytest suite

Next: Phase 7.2 Native Memory Model.
EOF

echo "[phase7.1] Running professional verification..."
bash scripts/verify_phase7_1_ai_runtime.sh

echo "============================================================"
echo " Phase 7.1 COMPLETE"
echo " Next: Phase 7.2 Native Memory Model"
echo "============================================================"
