#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.5 Documentation Generator Verification"
echo "============================================================"

test -f tools/docgen/panther_docgen.py
echo "✅ structure tests passed"

python3 tools/docgen/panther_docgen.py \
  examples/phase8_docgen/doc_demo.panther \
  --out docs/generated/doc_demo.md >/dev/null

test -f docs/generated/doc_demo.md
grep -q "PantherLang Documentation" docs/generated/doc_demo.md
grep -q "Phase 8.5 Documentation Generator" docs/generated/doc_demo.md
echo "✅ documentation generation tests passed"

./panther run examples/phase8_docgen/doc_demo.panther | grep -q "Phase 8.5 Documentation Generator"
echo "✅ runtime bridge tests passed"

python3 -m py_compile tools/docgen/panther_docgen.py
echo "✅ python compile passed"

echo "✅ PantherLang Phase 8.5 Documentation Generator verification complete."
