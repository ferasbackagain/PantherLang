#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="/tmp/panther_phase6_12_control_flow_$$.sh"
REPORT="$(./panther compile examples/phase6_control_flow/if_else_demo.panther --out "$OUT")"

echo "$REPORT" | grep -q '"ok": true'

RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Control flow if branch passed'
echo "$RUN_OUT" | grep -q 'Phase 6.12 control flow'

rm -f "$OUT"

echo "demo=phase6.12-control-flow"
echo "ok=true"
echo "if=true"
echo "artifact_runs=true"
