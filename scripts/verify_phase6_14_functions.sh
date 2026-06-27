#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.14 PRO Functions Verification"
echo "============================================================"
test -f compiler/functions/functions_engine.py
test -f examples/phase6_functions/function_demo.panther
test -x scripts/run_phase6_14_practical_demo.sh
test -f tests/phase6_14/test_functions.py
echo "✅ structure tests passed"
OUT="/tmp/panther_phase6_14_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_functions/function_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "✅ compiler function tests passed"
RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Hello from function'
echo "$RUN_OUT" | grep -q 'PantherLang'
echo "$RUN_OUT" | grep -q 'Phase 6.14 functions'
rm -f "$OUT"
echo "✅ emitted artifact function execution tests passed"
TMP_BAD="/tmp/panther_phase6_14_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
missing_fn()
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_fn.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_fn.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.14][ERROR] undefined function should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_14_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.14-functions'
echo "$PRACTICAL_OUT" | grep -q 'function_call=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical functions demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_14 >/tmp/panther_phase6_14_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/functions/functions_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.14 Functions verification complete."
