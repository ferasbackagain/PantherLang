#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.9 Debugger Verification"
echo "============================================================"

test -f tools/debugger/panther_debugger.py
test -f examples/phase8_debugger/debug_demo.panther
echo "✅ structure tests passed"

python3 tools/debugger/panther_debugger.py examples/phase8_debugger/debug_demo.panther --breakpoint 4 | grep -q '"ok": true'
python3 tools/debugger/panther_debugger.py examples/phase8_debugger/debug_demo.panther --breakpoint 4 | grep -q '"breakpoint": true'
echo "✅ debugger trace/breakpoint tests passed"

./panther debug examples/phase8_debugger/debug_demo.panther --breakpoint 4 | grep -q '"phase": "8.9"'
echo "✅ Panther debug CLI bridge tests passed"

./panther run examples/phase8_debugger/debug_demo.panther | grep -q "Phase 8.9 Debugger Foundation"
echo "✅ runtime bridge tests passed"

python3 -m py_compile tools/debugger/panther_debugger.py
echo "✅ python compile passed"

echo "✅ PantherLang Phase 8.9 Debugger Foundation verification complete."
