#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.10 PRO Final Runtime Verification FAST"
echo "============================================================"

test -f runtime/final_integration/final_runtime.py
test -f examples/phase7_final/final_runtime_demo.panther
test -x scripts/run_phase7_10_full_runtime_demo.sh
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.final_integration.final_runtime import PantherFinalRuntime
rt = PantherFinalRuntime()
report = rt.run_full_integration()
assert report.ok is True
assert report.scheduler_tasks == 1
assert report.messages == 1
assert report.context_ok is True
assert report.plugins == 2
assert report.sandbox_ok is True
assert report.distributed_nodes == 2
print("✅ real full runtime integration test passed")
PY

./panther run examples/phase7_final/final_runtime_demo.panther | grep -q "Phase 7 complete"
echo "✅ Panther CLI final runtime run test passed"

bash scripts/run_phase7_10_full_runtime_demo.sh | grep -q "demo=phase7.10-final-runtime"
echo "✅ practical full runtime demo passed"

python3 -m py_compile runtime/final_integration/final_runtime.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.10 Final Runtime Integration verification complete."
echo "✅ PantherLang Phase 7 is COMPLETE."
