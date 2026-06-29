#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.1 PRO AI Runtime Verification FAST"
echo "============================================================"

test -f runtime/ai_runtime/ai_runtime.py
test -f runtime/ai_runtime/runtime_api.py
test -f examples/phase7_runtime/runtime_demo.panther
echo "✅ structure tests passed"

python3 runtime/ai_runtime/runtime_api.py demo | grep -q '"ok": true'
echo "✅ runtime API demo passed"

OUT="/tmp/panther_phase7_1_fast_$$.sh"
./panther compile examples/phase7_runtime/runtime_demo.panther --out "$OUT" | grep -q '"ok": true'
bash "$OUT" | grep -q 'Phase 7.1 AI Runtime Foundation'
rm -f "$OUT"
echo "✅ compiler bridge passed"

echo "✅ PantherLang Phase 7.1 AI Runtime Foundation verification complete."
