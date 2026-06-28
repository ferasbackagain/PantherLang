#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.10 Final Developer Experience Verification FAST"
echo "============================================================"

test -f installer/install.sh
test -f package_manager/package_cli.py
test -f project_templates/template_cli.py
test -f stdlib/manifest.json
test -f tools/docgen/panther_docgen.py
test -f tools/formatter/panther_fmt.py
test -f tools/lsp/panther_lsp.py
test -f vscode-extension/package.json
test -f tools/debugger/panther_debugger.py
echo "✅ Phase 8 structure passed"

grep -q "package)" panther
grep -q "fmt)" panther
grep -q "lsp)" panther
grep -q "debug)" panther
grep -q "new)" panther
echo "✅ CLI command integration passed"

./panther run examples/phase8_debugger/debug_demo.panther >/tmp/p8_run.out
grep -q "Phase 8.9 Debugger Foundation" /tmp/p8_run.out

./panther lsp completions --prefix pr >/tmp/p8_lsp.out
grep -q "print" /tmp/p8_lsp.out

./panther fmt examples/phase8_formatter/format_demo.panther >/tmp/p8_fmt.out
grep -q "Phase 8.6 Formatter" /tmp/p8_fmt.out

./panther package list >/tmp/p8_pkg.out
grep -q "dependencies" /tmp/p8_pkg.out

./panther debug examples/phase8_debugger/debug_demo.panther --breakpoint 4 >/tmp/p8_debug.out
grep -q '"phase": "8.9"' /tmp/p8_debug.out
echo "✅ End-to-end developer workflow passed"

python3 -m py_compile \
 tools/docgen/panther_docgen.py \
 tools/formatter/panther_fmt.py \
 tools/lsp/panther_lsp.py \
 tools/debugger/panther_debugger.py \
 project_templates/template_cli.py \
 package_manager/package_cli.py
echo "✅ Toolchain compile passed"

echo "✅ PantherLang Phase 8.10 Final Developer Experience verification complete."
echo "✅ PantherLang Phase 8 is COMPLETE."
