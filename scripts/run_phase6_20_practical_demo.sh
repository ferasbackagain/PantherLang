#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="/tmp/panther_phase6_20_release_$$.sh"
REPORT="$(./panther compile examples/phase6_production/production_demo.panther --out "$OUT")"
echo "$REPORT" | grep -q '"ok": true'

RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Production readiness demo'
echo "$RUN_OUT" | grep -q 'PantherLang'
echo "$RUN_OUT" | grep -q '0.6.20'
echo "$RUN_OUT" | grep -q 'Phase 6.20 production readiness'

rm -f "$OUT"

echo "demo=phase6.20-production-readiness"
echo "ok=true"
echo "compile=true"
echo "run=true"
echo "release_ready=true"
echo "artifact_runs=true"
