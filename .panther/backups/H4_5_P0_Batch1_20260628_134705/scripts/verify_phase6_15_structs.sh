#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.15 PRO Structs Verification"
echo "============================================================"
test -f compiler/structs/structs_engine.py
test -f examples/phase6_structs/struct_demo.panther
test -x scripts/run_phase6_15_practical_demo.sh
test -f tests/phase6_15/test_structs.py
echo "✅ structure tests passed"
OUT="/tmp/panther_phase6_15_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_structs/struct_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "$COMPILE_JSON" | grep -q '"DECLARE_STRUCT"'
echo "✅ compiler struct tests passed"
RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Struct declaration test'
echo "$RUN_OUT" | grep -q 'Feras'
echo "$RUN_OUT" | grep -q 'Founder'
echo "$RUN_OUT" | grep -q 'Phase 6.15 structs'
rm -f "$OUT"
echo "✅ emitted artifact struct execution tests passed"
TMP_BAD="/tmp/panther_phase6_15_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
struct User {
    name
    name
}
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_struct.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_struct.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.15][ERROR] duplicate struct field should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_15_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.15-structs'
echo "$PRACTICAL_OUT" | grep -q 'struct_declaration=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical structs demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_15 >/tmp/panther_phase6_15_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/structs/structs_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.15 Structs verification complete."
