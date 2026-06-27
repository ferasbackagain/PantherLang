#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="/tmp/panther_phase6_19_fast_$$.sh"
REPORT="$(./panther compile examples/phase6_fast_regression/fast_regression_demo.panther --out "$OUT")"

echo "$REPORT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Fast regression demo'
echo "$RUN_OUT" | grep -q 'PantherLang'
echo "$RUN_OUT" | grep -q '6.19'

python3 tools/panther-regression/panther_regression.py --mode fast --timeout 180 >/tmp/panther_phase6_19_regression.json
grep -q '"ok": true' /tmp/panther_phase6_19_regression.json

rm -f "$OUT"

echo "demo=phase6.19-fast-regression"
echo "ok=true"
echo "compile=true"
echo "run=true"
echo "fast_regression=true"
echo "artifact_runs=true"
