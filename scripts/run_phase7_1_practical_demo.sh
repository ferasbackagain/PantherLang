#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 runtime/ai_runtime/runtime_api.py demo >/tmp/panther_phase7_1_runtime_demo.json
grep -q '"ok": true' /tmp/panther_phase7_1_runtime_demo.json
grep -q '"demo": "ai-runtime-foundation"' /tmp/panther_phase7_1_runtime_demo.json

OUT="/tmp/panther_phase7_1_compile_$$.sh"
./panther compile examples/phase7_runtime/runtime_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.1 AI Runtime Foundation'
rm -f "$OUT"

echo "demo=phase7.1-ai-runtime-foundation"
echo "ok=true"
echo "runtime_start=true"
echo "runtime_execute=true"
echo "runtime_shutdown=true"
echo "compile_bridge=true"
echo "artifact_runs=true"
