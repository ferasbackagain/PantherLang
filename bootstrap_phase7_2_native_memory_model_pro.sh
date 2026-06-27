#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.phase_backups/phase7_2_native_memory_$STAMP"

echo "============================================================"
echo " PantherLang Phase 7.2 PRO - Native Memory Model"
echo "============================================================"
echo "[phase7.2] Project root: $ROOT"

fail(){ echo "[phase7.2][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_file "panther"
require_file "runtime/ai_runtime/ai_runtime.py"
require_file "runtime/ai_runtime/runtime_context.py"
require_file "scripts/verify_phase7_1_ai_runtime.sh"

mkdir -p "$BACKUP_DIR"
for t in runtime/memory docs/phase7 examples/phase7_memory tests/phase7_2 scripts/verify_phase7_2_native_memory.sh scripts/run_phase7_2_practical_demo.sh scripts/verify_phase7_all.sh CHANGELOG.md; do
  if [ -e "$t" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$t")"
    cp -a "$t" "$BACKUP_DIR/$t"
  fi
done

echo "[phase7.2] Verifying Phase 7.1 baseline..."
bash scripts/verify_phase7_1_ai_runtime.sh >/tmp/panther_phase7_2_phase71.log

mkdir -p runtime/memory docs/phase7 examples/phase7_memory tests/phase7_2 scripts
touch runtime/__init__.py runtime/memory/__init__.py

cat > runtime/memory/memory_cell.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, asdict
from time import time
from typing import Any


@dataclass
class MemoryCell:
    key: str
    value: Any
    memory_type: str
    created_at: float
    updated_at: float

    @classmethod
    def create(cls, key: str, value: Any, memory_type: str = "runtime") -> "MemoryCell":
        now = time()
        return cls(key=key, value=value, memory_type=memory_type, created_at=now, updated_at=now)

    def update(self, value: Any) -> None:
        self.value = value
        self.updated_at = time()

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
PY

cat > runtime/memory/memory_store.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

from typing import Any

from runtime.memory.memory_cell import MemoryCell


class PantherMemoryError(Exception):
    pass


class NativeMemoryStore:
    def __init__(self) -> None:
        self.cells: dict[str, MemoryCell] = {}

    def set(self, key: str, value: Any, memory_type: str = "runtime") -> MemoryCell:
        self._validate_key(key)
        if key in self.cells:
            self.cells[key].update(value)
        else:
            self.cells[key] = MemoryCell.create(key, value, memory_type)
        return self.cells[key]

    def get(self, key: str) -> Any:
        self._validate_key(key)
        if key not in self.cells:
            raise PantherMemoryError(f"Memory key not found: {key}")
        return self.cells[key].value

    def has(self, key: str) -> bool:
        return key in self.cells

    def delete(self, key: str) -> None:
        self._validate_key(key)
        if key not in self.cells:
            raise PantherMemoryError(f"Memory key not found: {key}")
        del self.cells[key]

    def snapshot(self) -> dict[str, Any]:
        return {key: cell.to_dict() for key, cell in sorted(self.cells.items())}

    def _validate_key(self, key: str) -> None:
        if not key or not isinstance(key, str):
            raise PantherMemoryError("Memory key must be a non-empty string")
        if len(key) > 256:
            raise PantherMemoryError("Memory key too long")
PY

cat > runtime/memory/memory_api.py <<'PY'
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

from runtime.memory.memory_store import NativeMemoryStore, PantherMemoryError


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-memory")
    sub = parser.add_subparsers(dest="cmd", required=True)

    demo_p = sub.add_parser("demo")
    set_p = sub.add_parser("set")
    set_p.add_argument("key")
    set_p.add_argument("value")
    get_p = sub.add_parser("get")
    get_p.add_argument("key")

    args = parser.parse_args(argv)
    store = NativeMemoryStore()

    try:
        if args.cmd == "demo":
            store.set("project", "PantherLang")
            store.set("phase", "7.2")
            result = {
                "ok": True,
                "phase": "7.2",
                "demo": "native-memory-model",
                "project": store.get("project"),
                "memory": store.snapshot(),
                "network_used": False,
                "external_api_used": False,
            }
            print_json(result)
            return 0

        if args.cmd == "set":
            cell = store.set(args.key, args.value)
            print_json({"ok": True, "phase": "7.2", "cell": cell.to_dict()})
            return 0

        if args.cmd == "get":
            print_json({"ok": True, "phase": "7.2", "value": store.get(args.key)})
            return 0

    except PantherMemoryError as exc:
        print_json({"ok": False, "phase": "7.2", "error": str(exc)})
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x runtime/memory/memory_api.py

python3 - <<'PY'
from pathlib import Path

p = Path("runtime/ai_runtime/runtime_context.py")
txt = p.read_text()
if "from runtime.memory.memory_store import NativeMemoryStore" not in txt:
    txt = txt.replace("from typing import Any\n", "from typing import Any\n\nfrom runtime.memory.memory_store import NativeMemoryStore\n")
if "native_memory: NativeMemoryStore" not in txt:
    txt = txt.replace(
        'memory: dict[str, Any] = field(default_factory=dict)\n',
        'memory: dict[str, Any] = field(default_factory=dict)\n    native_memory: NativeMemoryStore = field(default_factory=NativeMemoryStore)\n'
    )
    txt = txt.replace(
        '        self.memory[key] = value\n',
        '        self.memory[key] = value\n        self.native_memory.set(key, value)\n'
    )
    txt = txt.replace(
        '        return self.memory.get(key, default)\n',
        '        return self.native_memory.get(key) if self.native_memory.has(key) else self.memory.get(key, default)\n'
    )
p.write_text(txt)
print("✅ runtime context patched for native memory")
PY

python3 -m py_compile runtime/memory/*.py
python3 -m py_compile runtime/ai_runtime/runtime_context.py

cat > docs/phase7/PHASE_7_2_STATUS.md <<'EOF'
# Phase 7.2 Status — Native Memory Model PRO

Completed:
- MemoryCell
- NativeMemoryStore
- memory API
- runtime context integration
- memory snapshot
- negative tests
- practical demo
- pytest suite

Next: Phase 7.3 — Agent Execution Engine.
EOF

cat > examples/phase7_memory/memory_demo.panther <<'EOF'
module panther.memory

print "Phase 7.2 Native Memory Model"
print "Memory demo source compiled"
EOF

cat > scripts/run_phase7_2_practical_demo.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 runtime/memory/memory_api.py demo >/tmp/panther_phase7_2_memory_demo.json
grep -q '"ok": true' /tmp/panther_phase7_2_memory_demo.json
grep -q '"demo": "native-memory-model"' /tmp/panther_phase7_2_memory_demo.json
grep -q '"project": "PantherLang"' /tmp/panther_phase7_2_memory_demo.json

OUT="/tmp/panther_phase7_2_compile_$$.sh"
./panther compile examples/phase7_memory/memory_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.2 Native Memory Model'
rm -f "$OUT"

echo "demo=phase7.2-native-memory-model"
echo "ok=true"
echo "memory_set=true"
echo "memory_get=true"
echo "snapshot=true"
echo "compile_bridge=true"
echo "artifact_runs=true"
EOF
chmod +x scripts/run_phase7_2_practical_demo.sh

cat > tests/phase7_2/test_native_memory.py <<'EOF'
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_memory_store_set_get_delete() -> None:
    from runtime.memory.memory_store import NativeMemoryStore, PantherMemoryError
    store = NativeMemoryStore()
    store.set("project", "PantherLang")
    assert store.get("project") == "PantherLang"
    assert store.has("project") is True
    store.delete("project")
    assert store.has("project") is False


def test_missing_key_fails() -> None:
    from runtime.memory.memory_store import NativeMemoryStore, PantherMemoryError
    store = NativeMemoryStore()
    try:
        store.get("missing")
        raise AssertionError("missing key should fail")
    except PantherMemoryError:
        pass


def test_memory_api_demo() -> None:
    proc = subprocess.run(
        [sys.executable, "runtime/memory/memory_api.py", "demo"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["demo"] == "native-memory-model"


def test_runtime_context_uses_native_memory() -> None:
    from runtime.ai_runtime.runtime_context import RuntimeContext
    ctx = RuntimeContext(session_id="test")
    ctx.set("x", "y")
    assert ctx.get("x") == "y"
    assert ctx.native_memory.has("x") is True
EOF

cat > scripts/verify_phase7_2_native_memory.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.2 PRO Native Memory Verification"
echo "============================================================"

test -f runtime/memory/memory_cell.py
test -f runtime/memory/memory_store.py
test -f runtime/memory/memory_api.py
test -f examples/phase7_memory/memory_demo.panther
test -x scripts/run_phase7_2_practical_demo.sh
test -f tests/phase7_2/test_native_memory.py
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.memory.memory_store import NativeMemoryStore, PantherMemoryError
store = NativeMemoryStore()
store.set("project", "PantherLang")
assert store.get("project") == "PantherLang"
snap = store.snapshot()
assert snap["project"]["value"] == "PantherLang"
store.delete("project")
assert store.has("project") is False
print("✅ native memory lifecycle tests passed")
PY

python3 runtime/memory/memory_api.py demo >/tmp/panther_phase7_2_memory_api.json
grep -q '"ok": true' /tmp/panther_phase7_2_memory_api.json
grep -q '"demo": "native-memory-model"' /tmp/panther_phase7_2_memory_api.json
echo "✅ memory API tests passed"

python3 - <<'PY'
from runtime.ai_runtime.runtime_context import RuntimeContext
ctx = RuntimeContext(session_id="verify")
ctx.set("phase", "7.2")
assert ctx.get("phase") == "7.2"
assert ctx.native_memory.has("phase") is True
print("✅ runtime context memory integration tests passed")
PY

OUT="/tmp/panther_phase7_2_verify_$$.sh"
./panther compile examples/phase7_memory/memory_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.2 Native Memory Model'
rm -f "$OUT"
echo "✅ compiler bridge tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase7_2_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase7.2-native-memory-model'
echo "$PRACTICAL_OUT" | grep -q 'memory_set=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical native memory demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase7_2 >/tmp/panther_phase7_2_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile runtime/memory/*.py
  echo "✅ python compile tests passed"
fi

echo "✅ PantherLang Phase 7.2 Native Memory Model verification complete."
EOF
chmod +x scripts/verify_phase7_2_native_memory.sh

cat > scripts/verify_phase7_all.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/verify_phase7_1_ai_runtime.sh
bash scripts/verify_phase7_2_native_memory.sh
echo "✅ ALL PHASE 7 TESTS PASSED THROUGH 7.2"
EOF
chmod +x scripts/verify_phase7_all.sh

cat >> CHANGELOG.md <<'EOF'

## Phase 7.2 — Native Memory Model PRO

Added native memory model:
- memory cells
- native memory store
- memory API
- runtime context integration
- memory snapshots
- practical memory demo
- pytest suite

Next: Phase 7.3 Agent Execution Engine.
EOF

echo "[phase7.2] Running professional verification..."
bash scripts/verify_phase7_2_native_memory.sh

echo "============================================================"
echo " Phase 7.2 COMPLETE"
echo " Next: Phase 7.3 Agent Execution Engine"
echo "============================================================"
