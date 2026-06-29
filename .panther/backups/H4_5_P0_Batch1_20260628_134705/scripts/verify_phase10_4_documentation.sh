#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 10.4 Documentation Verification"
echo "============================================================"

test -f website/index.html
test -f docs/reference/language_reference.md
test -f docs/api/cli.md
test -f docs/tutorials/quick_start.md
echo "✅ documentation structure passed"

grep -q "PantherLang" website/index.html
grep -q "Getting Started" website/index.html
echo "✅ website tests passed"

grep -q "Panther run" docs/tutorials/quick_start.md
grep -q "Panther doctor" docs/api/cli.md
echo "✅ documentation content passed"

Panther run examples/phase10_docs/documentation_demo.panther >/tmp/p104.log
grep -q "Phase 10.4 Official Documentation & Website" /tmp/p104.log
echo "✅ runtime bridge passed"

Panther build examples/phase10_docs/documentation_demo.panther --release >/tmp/p104build.json
grep -q '"ok": true' /tmp/p104build.json
test -f build/release/documentation_demo.sh
echo "✅ release build passed"

tar -czf /tmp/panther_docs_site.tar.gz website docs
test -f /tmp/panther_docs_site.tar.gz
echo "✅ documentation package passed"

echo "✅ PantherLang Phase 10.4 Official Documentation & Website verification complete."
