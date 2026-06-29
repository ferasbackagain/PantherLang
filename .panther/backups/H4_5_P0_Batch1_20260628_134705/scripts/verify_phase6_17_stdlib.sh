#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.17 PRO Standard Library Verification"
echo "============================================================"
test -f compiler/stdlib/stdlib_engine.py
test -f language/compiler/stdlib/stdlib_manifest.json
test -f language/stdlib/text/README.md
test -f language/stdlib/math/README.md
test -f language/stdlib/io/README.md
test -f examples/phase6_stdlib/stdlib_demo.panther
test -x scripts/run_phase6_17_practical_demo.sh
test -f tests/phase6_17/test_stdlib.py
echo "✅ structure tests passed"
OUT="/tmp/panther_phase6_17_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_stdlib/stdlib_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "✅ compiler stdlib tests passed"
RUN_OUT="$("$OUT")"
echo "$RUN_OUT" | grep -q 'Standard Library test'
echo "$RUN_OUT" | grep -q 'PANTHER'
echo "$RUN_OUT" | grep -q '15'
echo "$RUN_OUT" | grep -q '21'
echo "$RUN_OUT" | grep -q 'Phase 6.17 stdlib'
rm -f "$OUT"
echo "✅ emitted artifact stdlib execution tests passed"
TMP_BAD="/tmp/panther_phase6_17_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
print std.crypto.hash("x")
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_stdlib.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_stdlib.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.17][ERROR] unsupported stdlib call should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_17_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.17-stdlib'
echo "$PRACTICAL_OUT" | grep -q 'std_text=true'
echo "$PRACTICAL_OUT" | grep -q 'std_math=true'
echo "$PRACTICAL_OUT" | grep -q 'std_io=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical stdlib demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_17 >/tmp/panther_phase6_17_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/stdlib/stdlib_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.17 Standard Library verification complete."
