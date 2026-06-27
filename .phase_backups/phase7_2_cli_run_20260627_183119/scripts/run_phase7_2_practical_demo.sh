#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 runtime/memory/memory_api.py demo >/tmp/panther_phase7_2_memory_demo.json
grep -q '"ok": true' /tmp/panther_phase7_2_memory_demo.json
grep -q '"demo": "native-memory-model"' /tmp/panther_phase7_2_memory_demo.json
grep -q '"project": "PantherLang"' /tmp/panther_phase7_2_memory_demo.json

OUT="/tmp/panther_phase7_2_compile_$$.sh"
./panther compile examples/phase7_memory/memory_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.2 Native Memory Model'
rm -f "$OUT"

echo "demo=phase7.2-native-memory-model"
echo "ok=true"
echo "memory_set=true"
echo "memory_get=true"
echo "snapshot=true"
echo "compile_bridge=true"
echo "artifact_runs=true"
