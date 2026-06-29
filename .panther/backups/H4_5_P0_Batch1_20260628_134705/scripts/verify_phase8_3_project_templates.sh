#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
echo "============================================================"
echo " PantherLang Phase 8.3 Project Templates Verification"
echo "============================================================"
test -d templates/console
test -d templates/web
test -d templates/api
echo "✅ template structure passed"
TMP=$(mktemp -d)
(
cd "$TMP"
"$OLDPWD"/panther new console DemoApp >/dev/null
test -f DemoApp/src/main.panther
test -f DemoApp/panther.toml
)
rm -rf "$TMP"
echo "✅ project generation passed"
./panther run examples/phase8_templates/template_demo.panther | grep -q "Phase 8.3 Project Templates"
echo "✅ runtime bridge passed"
python3 -m py_compile project_templates/template_cli.py
echo "✅ python compile passed"
echo "✅ PantherLang Phase 8.3 Project Templates verification complete."
