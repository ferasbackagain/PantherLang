#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.11 Rev2 PRO Expressions Verification"
echo "============================================================"
bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_11_phase5_regression.log
echo "✅ Phase 5 regression tests passed"
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_11_phase6_10_regression.log
echo "✅ Phase 6.10 regression tests passed"
test -f compiler/expressions/expression_engine.py
test -f examples/phase6_expressions/expressions_demo.panther
test -x scripts/run_phase6_11_practical_demo.sh
echo "✅ structure tests passed"
python3 - <<'PY'
from compiler.expressions.expression_engine import ExpressionEngine, panther_format
e=ExpressionEngine({'a':10,'b':5}); assert e.evaluate('a + b')==15; assert e.evaluate('(a + b) * 2')==30; assert e.evaluate('30 == 30') is True; assert panther_format(False)=='false'
PY
echo "✅ import/self tests passed"
OUT="/tmp/panther_phase6_11_verify_expr_$$.sh"
./panther compile examples/phase6_expressions/expressions_demo.panther --out "$OUT" | grep -q '"ok": true'
echo "✅ compiler expression tests passed"
RUN_OUT="$($OUT)"
echo "$RUN_OUT" | grep -q 'Phase 6.11 expressions'
echo "$RUN_OUT" | grep -q '^15$'
echo "$RUN_OUT" | grep -q '^30$'
echo "$RUN_OUT" | grep -q '^true$'
rm -f "$OUT"
echo "✅ emitted artifact expression execution tests passed"
TMP_BAD="/tmp/panther_phase6_11_bad_$$.panther"
printf 'let x = 10 / 0\nprint x\n' > "$TMP_BAD"
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_expr.sh)"; BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_expr.sh
[ "$BAD_CODE" -eq 2 ] || { echo "division by zero should fail"; exit 1; }
echo "$BAD_OUT" | grep -q 'Division by zero'
echo "✅ negative/failure tests passed"
bash scripts/run_phase6_11_practical_demo.sh | grep -q 'artifact_runs=true'
echo "✅ practical expressions demo passed"
if command -v pytest >/dev/null 2>&1; then pytest -q tests/phase6_11 >/tmp/panther_phase6_11_pytest.log; echo "✅ pytest suite passed"; else python3 -m py_compile compiler/expressions/expression_engine.py compiler/pipeline/panther_compiler.py; echo "✅ python compile tests passed"; fi
echo "✅ PantherLang Phase 6.11 Rev2 Expressions Engine verification complete."
