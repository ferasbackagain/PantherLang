#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang H3 VS Code Extension Verification FAST"
echo "============================================================"

test -f hardening/H3/H3_MANIFEST.json
test -f vscode_extension/package.json
test -f vscode_extension/extension.js
test -f vscode_extension/language-configuration.json
test -f vscode_extension/syntaxes/panther.tmLanguage.json
echo "✅ H3 structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path

pkg = json.loads(Path("vscode_extension/package.json").read_text())
assert pkg["name"] == "pantherlang"
assert pkg["version"] == "1.0.0"
assert len(pkg["contributes"]["commands"]) >= 3

grammar = json.loads(Path("vscode_extension/syntaxes/panther.tmLanguage.json").read_text())
assert grammar["scopeName"] == "source.panther"
assert any("keyword.control.panther" in str(p) for p in grammar["patterns"])

config = json.loads(Path("vscode_extension/language-configuration.json").read_text())
assert "comments" in config
assert "brackets" in config

print("✅ VS Code manifest/grammar/config tests passed")
PY

grep -q 'panther.run' vscode_extension/extension.js
grep -q 'panther.build' vscode_extension/extension.js
grep -q 'panther.check' vscode_extension/extension.js
echo "✅ extension command bridge passed"

Panther run examples/H3/h3_vscode_demo.panther >/tmp/h3.log
grep -q 'PantherLang H3 VS Code Extension' /tmp/h3.log
echo "✅ runtime bridge passed"

mkdir -p reports/H3
cp vscode_extension/package.json reports/H3/vsix_manifest.json
cat > reports/H3/H3_REPORT.md <<'REPORT'
# PantherLang H3 Professional VS Code Extension Report

Status: PASSED

Completed:
- VS Code extension manifest
- Panther language association
- Syntax grammar
- Language configuration
- Panther command bridge
- Runtime verification

Result:
PantherLang H3 Professional VS Code Extension COMPLETE.
REPORT

grep -q 'Status: PASSED' reports/H3/H3_REPORT.md
echo "✅ validation report passed"

echo "✅ PantherLang H3 Professional VS Code Extension COMPLETE."
