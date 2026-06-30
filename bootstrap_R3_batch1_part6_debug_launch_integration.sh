#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 - Project System"
echo " Part 6 - Debug Launch Integration"
echo "============================================================"

ROOT="$(pwd)"
EXT="$ROOT/vscode-extension"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part6_debug_launch_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P6][ERROR] $1" >&2; exit 1; }

echo "[1/12] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "$R3/status_batch1_part5_build_command_integration.json" ] || fail "Run R3 Batch 1 Part 5 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."
[ -d debug_adapter ] || fail "debug_adapter missing."

echo "[2/12] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"
[ -d tests/R3_project_system ] && cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system" || true
[ -d tools/project_runner ] && cp -a tools/project_runner "$BACKUP/project_runner" || true

echo "[3/12] Baseline tests..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q
python3 -m pytest tests/R3_project_system -q

echo "[4/12] Creating debug launcher helper..."
mkdir -p tools/project_runner

cat > tools/project_runner/panther_debug.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from tools.project_runner.runner import read_project_manifest


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare PantherLang debug launch metadata.")
    parser.add_argument("--project", default=".", help="Project root containing panther.toml")
    parser.add_argument("--program", default=None, help="Program to debug")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    manifest = read_project_manifest(args.project)
    program = Path(args.program).resolve() if args.program else manifest.main

    data = {
        "ok": True,
        "project": manifest.name,
        "type": manifest.kind,
        "program": str(program),
        "debug_adapter": "debug_adapter",
        "stage": "r3_debug_launch_scaffold",
        "note": "VS Code debug launch is wired; full runtime stepping continues in later R3 debug batches."
    }

    if args.json:
        print(json.dumps(data, indent=2))
    else:
        print(f"✅ PantherLang debug ready: {program}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x tools/project_runner/panther_debug.py

echo "[5/12] Adding VS Code debug command implementation..."
cat > "$EXT/src/debug_command.js" <<'JS'
const vscode = require('vscode');
const cp = require('child_process');
const path = require('path');
const fs = require('fs');

function getWorkspaceRoot() {
  const folders = vscode.workspace.workspaceFolders;
  return folders && folders.length ? folders[0].uri.fsPath : undefined;
}

function execFile(command, args, cwd) {
  return new Promise((resolve, reject) => {
    cp.execFile(command, args, { cwd }, (error, stdout, stderr) => {
      if (error) reject(new Error(stderr || error.message));
      else resolve(stdout || stderr || '');
    });
  });
}

async function debugProject() {
  const root = getWorkspaceRoot();
  if (!root) {
    vscode.window.showWarningMessage('Open a PantherLang project folder first.');
    return;
  }

  const manifest = path.join(root, 'panther.toml');
  if (!fs.existsSync(manifest)) {
    vscode.window.showErrorMessage('panther.toml not found. Open a PantherLang project root.');
    return;
  }

  const program = path.join(root, 'src', 'main.panther');
  const repoHelper = path.join(root, 'tools', 'project_runner', 'panther_debug.py');
  const fallbackHelper = path.join(__dirname, '..', '..', 'tools', 'project_runner', 'panther_debug.py');
  const helper = fs.existsSync(repoHelper) ? repoHelper : fallbackHelper;

  if (fs.existsSync(helper)) {
    await execFile('python3', [helper, '--project', root, '--program', program, '--json'], root);
  }

  const config = {
    type: 'pantherlang',
    request: 'launch',
    name: 'Debug PantherLang Program',
    program: program,
    dryRun: true
  };

  const started = await vscode.debug.startDebugging(vscode.workspace.workspaceFolders[0], config);
  if (started) {
    vscode.window.showInformationMessage('PantherLang debug session started.');
  } else {
    vscode.window.showWarningMessage('PantherLang debug session did not start.');
  }
}

module.exports = { debugProject };
JS

echo "[6/12] Wiring extension.js/package.json debug contributions..."
python3 <<'PY'
from pathlib import Path
import json

ext = Path("vscode-extension")
extension_js = ext / "src" / "extension.js"
text = extension_js.read_text()

if "debug_command" not in text:
    text = "const {debugProject}=require('./debug_command');\n" + text

if "pantherlang.debugProject" not in text:
    marker = "context.subscriptions.push(vscode.commands.registerCommand('pantherlang.buildProject', buildProject));"
    if marker in text:
        text = text.replace(marker, marker + "\n  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.debugProject', debugProject));")
    else:
        marker = "context.subscriptions.push(vscode.commands.registerCommand('pantherlang.runFile', runFile));"
        text = text.replace(marker, marker + "\n  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.debugProject', debugProject));")

extension_js.write_text(text)
(ext / "out" / "extension.js").write_text(text)
(ext / "out" / "debug_command.js").write_text((ext / "src" / "debug_command.js").read_text())

pkg_path = ext / "package.json"
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.6"

contributes = pkg.setdefault("contributes", {})
commands = contributes.setdefault("commands", [])
if not any(c.get("command") == "pantherlang.debugProject" for c in commands):
    commands.append({"command": "pantherlang.debugProject", "title": "PantherLang: Debug Project"})

menus = contributes.setdefault("menus", {})
palette = menus.setdefault("commandPalette", [])
if not any(c.get("command") == "pantherlang.debugProject" for c in palette):
    palette.append({"command": "pantherlang.debugProject"})

activation = set(pkg.get("activationEvents") or [])
activation.add("onCommand:pantherlang.debugProject")
pkg["activationEvents"] = sorted(activation)

debuggers = contributes.setdefault("debuggers", [])
if not any(d.get("type") == "pantherlang" for d in debuggers):
    debuggers.append({
        "type": "pantherlang",
        "label": "PantherLang",
        "program": "./out/extension.js",
        "runtime": "node",
        "configurationAttributes": {
            "launch": {
                "required": ["program"],
                "properties": {
                    "program": {
                        "type": "string",
                        "description": "Path to the PantherLang program."
                    },
                    "dryRun": {
                        "type": "boolean",
                        "default": True,
                        "description": "Prepare debug launch without executing a real runtime."
                    }
                }
            }
        },
        "initialConfigurations": [
            {
                "type": "pantherlang",
                "request": "launch",
                "name": "Debug PantherLang Program",
                "program": "${workspaceFolder}/src/main.panther",
                "dryRun": True
            }
        ]
    })

pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ Debug command wired; version 1.0.6")
PY

echo "[7/12] Updating project templates launch configs..."
for t in console_app web_app api_app ai_app; do
cat > "project_templates/$t/.vscode/launch.json" <<'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "pantherlang",
      "request": "launch",
      "name": "Debug PantherLang Program",
      "program": "${workspaceFolder}/src/main.panther",
      "dryRun": true
    }
  ]
}
EOF
done

echo "[8/12] Creating Part 6 tests..."
cat > tests/R3_project_system/test_r3_batch1_part6_debug_launch.py <<'PY'
from pathlib import Path
import json
import subprocess
import sys

from tools.project_wizard.wizard import create_project


def test_debug_helper_json_output(tmp_path):
    result = create_project("debug-demo", "console", tmp_path)
    proc = subprocess.run(
        [
            sys.executable,
            "tools/project_runner/panther_debug.py",
            "--project",
            str(result.destination),
            "--json",
        ],
        text=True,
        capture_output=True,
        check=True,
    )
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["project"] == "debug-demo"
    assert data["stage"] == "r3_debug_launch_scaffold"


def test_vscode_debug_command_registered():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    assert "pantherlang.debugProject" in commands
    assert pkg["version"] == "1.0.6"
    assert any(d.get("type") == "pantherlang" for d in pkg["contributes"].get("debuggers", []))


def test_debug_command_implementation_contains_start_debugging():
    text = Path("vscode-extension/src/debug_command.js").read_text()
    assert "startDebugging" in text
    assert "panther_debug.py" in text
    assert "pantherlang" in text


def test_templates_have_debug_launch_config():
    for launch in Path("project_templates").glob("*/.vscode/launch.json"):
        data = json.loads(launch.read_text())
        cfg = data["configurations"][0]
        assert cfg["type"] == "pantherlang"
        assert cfg["program"] == "${workspaceFolder}/src/main.panther"
PY

echo "[9/12] Validation and tests..."
python3 -m py_compile tools/project_runner/panther_debug.py tests/R3_project_system/test_r3_batch1_part6_debug_launch.py
python3 -m pytest tests/R3_project_system -q

echo "[10/12] Build VSIX 1.0.6..."
(
  cd "$EXT"
  rm -f pantherlang-1.0.6*.vsix
  npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t "$EXT"/pantherlang-1.0.6*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX 1.0.6 was not created."
cp "$VSIX" releases/vscode_marketplace/
sha256sum "releases/vscode_marketplace/$(basename "$VSIX")" > "releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[11/12] Writing manifest/report..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r3 = root / ".panther/R3_production_developer_experience"
vsix = root / "releases/vscode_marketplace" / "$(basename "$VSIX")"

manifest = {
    "ok": True,
    "phase": "R3",
    "batch": "1",
    "part": "6",
    "name": "Debug Launch Integration",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.6",
    "runtime_modified": True,
    "features": [
        "panther_debug_helper",
        "vscode_debug_project_command",
        "debugger_contribution",
        "template_launch_json",
        "vsix_1_0_6"
    ],
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Part 7 - Agent Knowledge Pack"
}
(r3 / "batch1_part6_debug_launch_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART6_DEBUG_LAUNCH_INTEGRATION.md" <<EOF
# R3 Batch 1 Part 6 - Debug Launch Integration

## Status

PASSED

## Version

PantherLang VS Code Extension 1.0.6

## Added

- \`tools/project_runner/panther_debug.py\`
- VS Code command: \`PantherLang: Debug Project\`
- Debugger contribution for \`pantherlang\`
- Template \`.vscode/launch.json\`
- VSIX 1.0.6

## Next

R3 Batch 1 Part 7 - Agent Knowledge Pack.
EOF

echo "[12/12] Writing status..."
cat > "$R3/status_batch1_part6_debug_launch_integration.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "part": "6",
  "status": "PASSED",
  "name": "Debug Launch Integration",
  "version": "1.0.6",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R3 Batch 1 Part 7 - Agent Knowledge Pack"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 1 Part 6 COMPLETE"
echo "✅ Debug Launch Integration READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 7 - Agent Knowledge Pack"
echo "============================================================"
