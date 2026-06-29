#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.2 PRO Native Memory Verification FAST"
echo "============================================================"

test -f runtime/memory/memory_cell.py
test -f runtime/memory/memory_store.py
test -f runtime/memory/memory_api.py
test -f examples/phase7_memory/memory_demo.panther
test -x scripts/run_phase7_2_practical_demo.sh
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.memory.memory_store import NativeMemoryStore
store = NativeMemoryStore()
store.set("project", "PantherLang")
assert store.get("project") == "PantherLang"
assert store.snapshot()["project"]["value"] == "PantherLang"
store.delete("project")
assert store.has("project") is False
print("✅ native memory lifecycle tests passed")
PY

python3 runtime/memory/memory_api.py demo | grep -q '"ok": true'
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
bash "$OUT" | grep -q 'Phase 7.2 Native Memory Model'
rm -f "$OUT"
echo "✅ compiler bridge tests passed"

bash scripts/run_phase7_2_practical_demo.sh | grep -q 'demo=phase7.2-native-memory-model'
echo "✅ practical native memory demo passed"

python3 -m py_compile runtime/memory/*.py
python3 -m py_compile runtime/ai_runtime/runtime_context.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.2 Native Memory Model verification complete."
