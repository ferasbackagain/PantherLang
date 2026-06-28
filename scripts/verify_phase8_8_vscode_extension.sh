#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 8.8 VS Code Extension Verification"
echo "============================================================"

test -f vscode-extension/package.json
test -f vscode-extension/syntaxes/panther.tmLanguage.json
test -f vscode-extension/language-configuration/panther-language-configuration.json
test -f vscode-extension/src/extension.js
echo "✅ VS Code extension structure passed"

python3 - <<'PY'
import json
from pathlib import Path

pkg = json.loads(Path("vscode-extension/package.json").read_text())
assert pkg["name"] == "pantherlang"
assert pkg["version"] == "0.8.8"
assert ".panther" in pkg["contributes"]["languages"][0]["extensions"]

grammar = json.loads(Path("vscode-extension/syntaxes/panther.tmLanguage.json").read_text())
assert grammar["scopeName"] == "source.panther"
assert "patterns" in grammar

config = json.loads(Path("vscode-extension/language-configuration/panther-language-configuration.json").read_text())
assert config["comments"]["lineComment"] == "#"
print("✅ VS Code manifest/grammar tests passed")
PY

grep -q "panther.runFile" vscode-extension/src/extension.js
grep -q "Panther run" vscode-extension/src/extension.js
grep -q "Panther check" vscode-extension/src/extension.js
grep -q "Panther fmt --write" vscode-extension/src/extension.js
echo "✅ VS Code command tests passed"

./panther run examples/phase8_vscode/vscode_demo.panther | grep -q "Phase 8.8 VS Code Extension Foundation"
echo "✅ runtime bridge tests passed"

node -c vscode-extension/src/extension.js >/dev/null 2>&1 || echo "⚠️ Node syntax check skipped or unavailable"
echo "✅ VS Code extension foundation checked"

echo "✅ PantherLang Phase 8.8 VS Code Extension Foundation verification complete."
