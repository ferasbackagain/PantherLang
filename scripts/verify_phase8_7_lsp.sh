#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.7 LSP Verification"
echo "============================================================"

test -f tools/lsp/panther_lsp.py
test -f examples/phase8_lsp/lsp_demo.panther
echo "✅ structure tests passed"

python3 tools/lsp/panther_lsp.py diagnostics examples/phase8_lsp/lsp_demo.panther | grep -q '"ok": true'
echo "✅ diagnostics tests passed"

python3 tools/lsp/panther_lsp.py completions --prefix pr | grep -q 'print'
echo "✅ completions tests passed"

python3 tools/lsp/panther_lsp.py hover fn | grep -q 'Declares a function'
echo "✅ hover tests passed"

./panther lsp completions --prefix mo | grep -q 'module'
echo "✅ Panther LSP CLI bridge tests passed"

./panther run examples/phase8_lsp/lsp_demo.panther | grep -q "Phase 8.7 Language Server Protocol"
echo "✅ runtime bridge tests passed"

python3 -m py_compile tools/lsp/panther_lsp.py
echo "✅ python compile passed"

echo "✅ PantherLang Phase 8.7 Language Server Protocol verification complete."
