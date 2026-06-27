#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 6.13 PRO Loops Verification"
echo "============================================================"
bash scripts/verify_phase5_all.sh >/tmp/panther_phase6_13_phase5.log
echo "✅ Phase 5 regression tests passed"
bash scripts/verify_phase6_10_final_compiler_integration.sh >/tmp/panther_phase6_13_phase610.log
echo "✅ Phase 6.10 regression tests passed"
bash scripts/verify_phase6_11_expressions_engine.sh >/tmp/panther_phase6_13_phase611.log
echo "✅ Phase 6.11 regression tests passed"
bash scripts/verify_phase6_12_control_flow.sh >/tmp/panther_phase6_13_phase612.log
echo "✅ Phase 6.12 regression tests passed"
test -f architecture/LOOPS_ENGINE.md
test -f language/compiler/loops/loops_manifest.json
test -f compiler/loops/loops_engine.py
test -f examples/phase6_loops/for_loop_demo.panther
test -x scripts/run_phase6_13_practical_demo.sh
test -f tests/phase6_13/test_loops.py
test -f docs/phase6/PHASE_6_13_STATUS.md
echo "✅ structure tests passed"
python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/compiler/loops/loops_manifest.json").read_text())
assert m["phase"] == "6.13"
assert m["external_api_required"] is False
assert "for_loop" in m["features"]
assert "range_loop" in m["features"]
PY
echo "✅ manifest tests passed"
OUT="/tmp/panther_phase6_13_verify_$$.sh"
COMPILE_JSON="$(./panther compile examples/phase6_loops/for_loop_demo.panther --out "$OUT")"
echo "$COMPILE_JSON" | grep -q '"ok": true'
echo "✅ compiler loop tests passed"
RUN_OUT="$("$OUT")"
test "$(echo "$RUN_OUT" | grep -c 'Loop iteration')" = "3"
echo "$RUN_OUT" | grep -q 'Phase 6.13 loops'
rm -f "$OUT"
echo "✅ emitted artifact loop execution tests passed"
TMP_BAD="/tmp/panther_phase6_13_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
for i in 5..1 {
    print i
}
BAD
set +e
BAD_OUT="$(./panther compile "$TMP_BAD" --out /tmp/panther_bad_loop.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_loop.sh
if [ "$BAD_CODE" -ne 2 ]; then
  echo "[verify_phase6.13][ERROR] invalid loop should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"
PRACTICAL_OUT="$(bash scripts/run_phase6_13_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=phase6.13-loops'
echo "$PRACTICAL_OUT" | grep -q 'for_loop=true'
echo "$PRACTICAL_OUT" | grep -q 'artifact_runs=true'
echo "✅ practical loops demo passed"
if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase6_13 >/tmp/panther_phase6_13_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile compiler/loops/loops_engine.py
  python3 -m py_compile compiler/pipeline/panther_compiler.py
  echo "✅ python compile tests passed"
fi
echo "✅ PantherLang Phase 6.13 Loops verification complete."
