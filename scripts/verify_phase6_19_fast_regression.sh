#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 6.19 PRO Fast Regression Verification FAST"
echo "============================================================"

test -f compiler/optimization/optimizer.py
test -f tools/panther-regression/panther_regression.py
test -f examples/phase6_fast_regression/fast_regression_demo.panther
test -x scripts/run_phase6_19_practical_demo.sh
echo "✅ structure tests passed"

python3 - <<'PY'
from compiler.optimization.optimizer import stable_fingerprint, optimize_ir
assert stable_fingerprint("x") == stable_fingerprint("x")
assert stable_fingerprint("x") != stable_fingerprint("y")
ir, meta = optimize_ir([{"op": "NOOP"}, {"op": "PRINT", "value": "x"}])
assert len(ir) == 1
assert meta["removed_noops"] == 1
print("✅ optimizer tests passed")
PY

OUT="/tmp/panther_phase6_19_verify_$$.sh"
./panther compile examples/phase6_fast_regression/fast_regression_demo.panther --out "$OUT" | grep -q '"ok": true'
echo "✅ compiler optimization tests passed"

RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Fast regression demo'
echo "$RUN_OUT" | grep -q 'PantherLang'
echo "$RUN_OUT" | grep -q '6.19'
rm -f "$OUT"
echo "✅ emitted artifact execution tests passed"

python3 -m py_compile compiler/optimization/optimizer.py
python3 -m py_compile tools/panther-regression/panther_regression.py
python3 -m py_compile compiler/pipeline/panther_compiler.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 6.19 Compiler Optimization & Fast Regression verification complete."
