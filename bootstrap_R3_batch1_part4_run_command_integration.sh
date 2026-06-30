#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 - Project System"
echo " Part 4 - Run Command Integration"
echo "============================================================"

ROOT="$(pwd)"
EXT="$ROOT/vscode-extension"
R3="$ROOT/.panther/R3_production_developer_experience"
mkdir -p "$R3"

fail(){ echo "[ERROR] $1"; exit 1; }

[ -f "$R3/status_batch1_part3_templates_professionalization.json" ] || fail "Complete Part 3 first."

echo "[1/8] Updating extension to 1.0.4..."
python3 <<'PY'
from pathlib import Path
import json
p=Path("vscode-extension/package.json")
pkg=json.loads(p.read_text())
pkg["version"]="1.0.4"
p.write_text(json.dumps(pkg,indent=2)+"\n")
PY

echo "[2/8] Wiring Run command..."
cat > "$EXT/src/run_command.js" <<'JS'
const vscode=require("vscode");
const cp=require("child_process");

async function runCurrentFile(){
 const ed=vscode.window.activeTextEditor;
 if(!ed){vscode.window.showWarningMessage("No PantherLang file open.");return;}
 const file=ed.document.fileName;
 const term=vscode.window.createTerminal("PantherLang Run");
 term.show();
 term.sendText(`panther run "${file}"`);
}
module.exports={runCurrentFile};
JS

python3 <<'PY'
from pathlib import Path
p=Path("vscode-extension/src/extension.js")
t=p.read_text()
if 'run_command' not in t:
    t="const {runCurrentFile}=require('./run_command');\n"+t
t=t.replace("() => runFile()","() => runCurrentFile()")
p.write_text(t)
Path("vscode-extension/out/extension.js").write_text(t)
PY

echo "[3/8] Creating tests..."
mkdir -p tests/R3_project_system
cat > tests/R3_project_system/test_r3_batch1_part4_run.py <<'PY'
from pathlib import Path
import json
def test_version():
    pkg=json.loads(Path("vscode-extension/package.json").read_text())
    assert pkg["version"]=="1.0.4"
def test_run_module():
    t=Path("vscode-extension/src/run_command.js").read_text()
    assert "panther run" in t
PY

echo "[4/8] Running tests..."
python3 -m pytest tests/R3_project_system -q

echo "[5/8] Building VSIX..."
(
cd "$EXT"
rm -f pantherlang-1.0.4*.vsix
npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX=$(ls -t "$EXT"/pantherlang-1.0.4*.vsix|head -1)
cp "$VSIX" releases/vscode_marketplace/

echo "[6/8] Writing status..."
cat > "$R3/status_batch1_part4_run_command_integration.json" <<EOF
{"ok":true,"phase":"R3","batch":"1","part":"4","version":"1.0.4","next":"R3 Batch 1 Part 5 - Build Command Integration"}
EOF

echo "[7/8] Done."

echo "============================================================"
echo "✅ R3 Batch 1 Part 4 COMPLETE"
echo "✅ Run Command Integration READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 5 - Build Command Integration"
echo "============================================================"
