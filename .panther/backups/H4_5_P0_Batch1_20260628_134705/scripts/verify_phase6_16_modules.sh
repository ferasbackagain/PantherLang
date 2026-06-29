#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.16 PRO Modules Verification"
echo "============================================================"
test -f compiler/modules/modules_engine.py
test -f examples/phase6_modules/module_demo.panther
test -x scripts/run_phase6_16_practical_demo.sh
test -f tests/phase6_16/test_modules.py
echo "✅ structure tests passed"
OUT="/tmp/panther_phase6_16_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_modules/module_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "$COMPILE_JSON" | grep -q '"DECLARE_MODULE"'
echo "$COMPILE_JSON" | grep -q '"IMPORT_MODULE"'
echo "✅ compiler module tests passed"
RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Module declaration test'
echo "$RUN_OUT" | grep -q 'Panther Module System'
echo "$RUN_OUT" | grep -q '0.6.16'
echo "$RUN_OUT" | grep -q 'Phase 6.16 modules'
rm -f "$OUT"
echo "✅ emitted artifact module execution tests passed"
TMP_BAD="/tmp/panther_phase6_16_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
module 123.bad
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_module.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_module.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.16][ERROR] invalid module should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_16_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.16-modules'
echo "$PRACTICAL_OUT" | grep -q 'module_declaration=true'
echo "$PRACTICAL_OUT" | grep -q 'imports=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical modules demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_16 >/tmp/panther_phase6_16_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/modules/modules_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.16 Modules verification complete."
