#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 6.12 PRO Control Flow Verification FAST"
echo "============================================================"

test -f compiler/control_flow/control_flow_engine.py
test -f examples/phase6_control_flow/if_else_demo.panther
test -x scripts/run_phase6_12_practical_demo.sh
echo "✅ structure tests passed"

OUT="/tmp/panther_phase6_12_verify_$$.sh"
timeout 30 ./panther compile examples/phase6_control_flow/if_else_demo.panther --out "$OUT" | grep -q '"ok": true'
echo "✅ compiler control-flow tests passed"

RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Control flow then branch passed'
echo "$RUN_OUT" | grep -q 'Phase 6.12 control flow'
rm -f "$OUT"
echo "✅ emitted artifact control-flow execution tests passed"

TMP_BAD="/tmp/panther_phase6_12_bad_$$.panther"
cat > "$TMP_BAD" <<'BAD'
if true
    print "bad"
BAD

set +e
BAD_OUT="$(timeout 30 ./panther compile "$TMP_BAD" --out /tmp/panther_bad_if.sh)"
BAD_CODE=$?
set -e
rm -f "$TMP_BAD" /tmp/panther_bad_if.sh

if [ "$BAD_CODE" -eq 0 ]; then
  echo "[verify_phase6.12][ERROR] invalid if should fail"
  exit 1
fi
echo "✅ negative/failure tests passed"

bash scripts/run_phase6_12_practical_demo.sh | grep -q 'demo=phase6.12-control-flow'
echo "✅ practical control-flow demo passed"

echo "✅ PantherLang Phase 6.12 Control Flow verification complete."
