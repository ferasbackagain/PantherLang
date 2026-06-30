#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Production Developer Experience"
echo " Batch 1 - Project System"
echo " Part 1 - Project Wizard Foundation"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part1_project_wizard_$(date +%Y%m%d_%H%M%S)"
EXT="$ROOT/vscode-extension"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P1][ERROR] $1" >&2; exit 1; }

echo "[1/12] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f ".panther/R1_product_unification/status_R1_final_integration.json" ] || fail "R1 final integration missing."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/12] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"
[ -d project_templates ] && cp -a project_templates "$BACKUP/project_templates" || true
[ -d tests/R3_project_system ] && cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system" || true

echo "[3/12] Baseline regression..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

echo "[4/12] Creating Panther project templates..."
mkdir -p project_templates/console_app/src project_templates/web_app/src project_templates/web_app/public project_templates/api_app/src project_templates/ai_app/src

cat > project_templates/console_app/panther.toml <<'EOF'
[project]
name = "{{PROJECT_NAME}}"
type = "console"
version = "0.1.0"
language = "panther"

[run]
main = "src/main.panther"
EOF

cat > project_templates/console_app/src/main.panther <<'EOF'
panther main {
    print("Hello from {{PROJECT_NAME}}")
}
EOF

cat > project_templates/web_app/panther.toml <<'EOF'
[project]
name = "{{PROJECT_NAME}}"
type = "web"
version = "0.1.0"
language = "panther"

[run]
main = "src/main.panther"
EOF

cat > project_templates/web_app/src/main.panther <<'EOF'
panther web {
    route "/" {
        return "Hello from {{PROJECT_NAME}} Web App"
    }
}
EOF

cat > project_templates/web_app/public/index.html <<'EOF'
<!doctype html>
<html>
  <head><title>{{PROJECT_NAME}}</title></head>
  <body><h1>{{PROJECT_NAME}}</h1></body>
</html>
EOF

cat > project_templates/api_app/panther.toml <<'EOF'
[project]
name = "{{PROJECT_NAME}}"
type = "api"
version = "0.1.0"
language = "panther"

[run]
main = "src/main.panther"
EOF

cat > project_templates/api_app/src/main.panther <<'EOF'
panther api {
    get "/health" {
        return { "status": "ok", "service": "{{PROJECT_NAME}}" }
    }
}
EOF

cat > project_templates/ai_app/panther.toml <<'EOF'
[project]
name = "{{PROJECT_NAME}}"
type = "ai"
version = "0.1.0"
language = "panther"

[run]
main = "src/main.panther"
EOF

cat > project_templates/ai_app/src/main.panther <<'EOF'
panther ai {
    prompt = "Build safely with PantherLang"
    print("AI-ready Panther project: {{PROJECT_NAME}}")
}
EOF

echo "[5/12] Creating Python project wizard engine..."
mkdir -p tools/project_wizard

cat > tools/project_wizard/__init__.py <<'EOF'
from .wizard import create_project, available_templates

__all__ = ["create_project", "available_templates"]
EOF

cat > tools/project_wizard/wizard.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import shutil


TEMPLATE_MAP = {
    "console": "console_app",
    "web": "web_app",
    "api": "api_app",
    "ai": "ai_app",
}


@dataclass(frozen=True)
class ProjectResult:
    name: str
    template: str
    destination: Path
    files_created: int


def available_templates() -> list[str]:
    return sorted(TEMPLATE_MAP.keys())


def _safe_project_name(name: str) -> str:
    cleaned = "".join(ch for ch in name.strip() if ch.isalnum() or ch in ("-", "_"))
    if not cleaned:
        raise ValueError("project name cannot be empty")
    return cleaned


def _render_text(text: str, project_name: str) -> str:
    return text.replace("{{PROJECT_NAME}}", project_name)


def create_project(name: str, template: str = "console", destination: str | Path = ".") -> ProjectResult:
    project_name = _safe_project_name(name)
    template_key = template.strip().lower()
    if template_key not in TEMPLATE_MAP:
        raise ValueError(f"unknown template: {template}. Available: {', '.join(available_templates())}")

    root = Path(__file__).resolve().parents[2]
    template_dir = root / "project_templates" / TEMPLATE_MAP[template_key]
    if not template_dir.exists():
        raise FileNotFoundError(f"template directory not found: {template_dir}")

    dest_root = Path(destination).resolve()
    project_dir = dest_root / project_name
    if project_dir.exists():
        raise FileExistsError(f"destination already exists: {project_dir}")

    files_created = 0
    for src in template_dir.rglob("*"):
        rel = src.relative_to(template_dir)
        dst = project_dir / rel
        if src.is_dir():
            dst.mkdir(parents=True, exist_ok=True)
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        try:
            text = src.read_text(encoding="utf-8")
            dst.write_text(_render_text(text, project_name), encoding="utf-8")
        except UnicodeDecodeError:
            shutil.copy2(src, dst)
        files_created += 1

    return ProjectResult(project_name, template_key, project_dir, files_created)
PY

cat > tools/project_wizard/panther_new.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from tools.project_wizard.wizard import available_templates, create_project


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a new PantherLang project.")
    parser.add_argument("name", help="Project name")
    parser.add_argument("--template", default="console", choices=available_templates())
    parser.add_argument("--destination", default=".")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = create_project(args.name, args.template, Path(args.destination))
    if args.json:
        print(json.dumps({
            "ok": True,
            "name": result.name,
            "template": result.template,
            "destination": str(result.destination),
            "files_created": result.files_created,
        }, indent=2))
    else:
        print(f"✅ Created PantherLang {result.template} project: {result.destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x tools/project_wizard/panther_new.py

echo "[6/12] Wiring VS Code command metadata..."
python3 <<'PY'
from pathlib import Path
import json

pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.1"

contributes = pkg.setdefault("contributes", {})
commands = contributes.setdefault("commands", [])

def ensure_command(command: str, title: str):
    if not any(c.get("command") == command for c in commands):
        commands.append({"command": command, "title": title})

for command, title in [
    ("pantherlang.newProject", "PantherLang: New Project"),
    ("pantherlang.newConsoleProject", "PantherLang: New Console Project"),
    ("pantherlang.newWebProject", "PantherLang: New Web Project"),
    ("pantherlang.newApiProject", "PantherLang: New API Project"),
    ("pantherlang.newAiProject", "PantherLang: New AI Project"),
    ("pantherlang.runFile", "PantherLang: Run Current File"),
    ("pantherlang.doctor", "PantherLang: Doctor"),
]:
    ensure_command(command, title)

activation = set(pkg.get("activationEvents") or [])
activation.update([
    "onLanguage:pantherlang",
    "onCommand:pantherlang.newProject",
    "onCommand:pantherlang.newConsoleProject",
    "onCommand:pantherlang.newWebProject",
    "onCommand:pantherlang.newApiProject",
    "onCommand:pantherlang.newAiProject",
    "onCommand:pantherlang.runFile",
    "onCommand:pantherlang.doctor",
])
pkg["activationEvents"] = sorted(activation)

pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ VS Code package commands aligned")
PY

echo "[7/12] Creating VS Code extension command implementation..."
mkdir -p "$EXT/src" "$EXT/out"

cat > "$EXT/src/extension.js" <<'JS'
const vscode = require('vscode');
const cp = require('child_process');
const path = require('path');

function runCommand(command, args, cwd) {
  return new Promise((resolve, reject) => {
    cp.execFile(command, args, { cwd }, (error, stdout, stderr) => {
      if (error) reject(new Error(stderr || error.message));
      else resolve(stdout || stderr || '');
    });
  });
}

async function createProject(template) {
  const name = await vscode.window.showInputBox({
    prompt: `New PantherLang ${template} project name`,
    value: template === 'console' ? 'hello-panther' : `hello-${template}`
  });
  if (!name) return;

  const folders = vscode.workspace.workspaceFolders;
  const destination = folders && folders.length ? folders[0].uri.fsPath : process.cwd();
  const root = folders && folders.length ? folders[0].uri.fsPath : destination;
  const script = path.join(root, 'tools', 'project_wizard', 'panther_new.py');

  try {
    await runCommand('python3', [script, name, '--template', template, '--destination', destination, '--json'], root);
    vscode.window.showInformationMessage(`PantherLang project created: ${name}`);
    await vscode.commands.executeCommand('vscode.openFolder', vscode.Uri.file(path.join(destination, name)), { forceNewWindow: false });
  } catch (err) {
    vscode.window.showErrorMessage(`PantherLang project creation failed: ${err.message}`);
  }
}

async function doctor() {
  vscode.window.showInformationMessage('PantherLang v1.0.1 Developer Experience: extension active.');
}

async function runFile() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage('No active PantherLang file.');
    return;
  }
  const terminal = vscode.window.createTerminal('PantherLang');
  terminal.show();
  terminal.sendText(`echo "PantherLang run placeholder: ${editor.document.fileName}"`);
}

function activate(context) {
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newProject', () => createProject('console')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newConsoleProject', () => createProject('console')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newWebProject', () => createProject('web')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newApiProject', () => createProject('api')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newAiProject', () => createProject('ai')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.doctor', doctor));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.runFile', runFile));
}

function deactivate() {}

module.exports = { activate, deactivate };
JS

cp "$EXT/src/extension.js" "$EXT/out/extension.js"

echo "[8/12] Creating R3 tests..."
mkdir -p tests/R3_project_system

cat > tests/R3_project_system/test_r3_batch1_part1_project_wizard.py <<'PY'
from pathlib import Path
import json
import subprocess
import sys

from tools.project_wizard.wizard import available_templates, create_project


def test_available_templates():
    assert available_templates() == ["ai", "api", "console", "web"]


def test_create_console_project(tmp_path):
    result = create_project("hello-panther", "console", tmp_path)
    assert result.files_created >= 2
    project = tmp_path / "hello-panther"
    assert (project / "panther.toml").exists()
    assert (project / "src" / "main.panther").exists()
    assert "hello-panther" in (project / "panther.toml").read_text()
    assert "hello-panther" in (project / "src" / "main.panther").read_text()


def test_create_all_templates(tmp_path):
    for template in available_templates():
        result = create_project(f"demo-{template}", template, tmp_path)
        assert result.destination.exists()
        assert (result.destination / "panther.toml").exists()


def test_cli_json_output(tmp_path):
    proc = subprocess.run(
        [
            sys.executable,
            "tools/project_wizard/panther_new.py",
            "json-demo",
            "--template",
            "api",
            "--destination",
            str(tmp_path),
            "--json",
        ],
        text=True,
        capture_output=True,
        check=True,
    )
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["name"] == "json-demo"
    assert data["template"] == "api"
    assert Path(data["destination"]).exists()
PY

echo "[9/12] Static validation and R3 tests..."
python3 -m py_compile tools/project_wizard/__init__.py tools/project_wizard/wizard.py tools/project_wizard/panther_new.py tests/R3_project_system/test_r3_batch1_part1_project_wizard.py
python3 -m pytest tests/R3_project_system/test_r3_batch1_part1_project_wizard.py -q

echo "[10/12] Rebuild VSIX 1.0.1..."
cd "$EXT"
npx --yes @vscode/vsce package --no-dependencies
cd "$ROOT"

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t "$EXT"/pantherlang-1.0.1*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX 1.0.1 was not created."
cp "$VSIX" releases/vscode_marketplace/
sha256sum "releases/vscode_marketplace/$(basename "$VSIX")" > "releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[11/12] Writing R3 manifest and report..."
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
    "part": "1",
    "name": "Project Wizard Foundation",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.1",
    "runtime_modified": True,
    "features": [
        "project_templates_console",
        "project_templates_web",
        "project_templates_api",
        "project_templates_ai",
        "python_project_wizard_engine",
        "panther_new_cli",
        "vscode_new_project_commands",
        "vsix_1_0_1"
    ],
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Part 2 - Project Wizard UX Integration"
}
(r3 / "batch1_part1_project_wizard_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART1_PROJECT_WIZARD_FOUNDATION.md" <<EOF
# R3 Batch 1 Part 1 - Project Wizard Foundation

## Status

PASSED

## Version

PantherLang VS Code Extension 1.0.1

## Added

- Console App template
- Web App template
- API App template
- AI App template
- Project wizard Python engine
- \`tools/project_wizard/panther_new.py\`
- VS Code commands for New Panther Project
- R3 project system tests
- VSIX 1.0.1 package

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R3 Batch 1 Part 2 - Project Wizard UX Integration.
EOF

echo "[12/12] Writing status..."
cat > "$R3/status_batch1_part1_project_wizard_foundation.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "part": "1",
  "status": "PASSED",
  "name": "Project Wizard Foundation",
  "version": "1.0.1",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R3 Batch 1 Part 2 - Project Wizard UX Integration"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 1 Part 1 COMPLETE"
echo "✅ Project Wizard Foundation READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 2 - Project Wizard UX Integration"
echo "============================================================"
