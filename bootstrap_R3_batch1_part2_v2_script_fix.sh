#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 Part 2 v2 - Project Wizard UX Script Fix"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part2_v2_script_fix_$(date +%Y%m%d_%H%M%S)"
EXT="$ROOT/vscode-extension"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P2-v2][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight..."
[ -f "$R3/status_batch1_part1_project_wizard_foundation.json" ] || fail "Run R3 Batch 1 Part 1 first."
[ -f "tools/project_wizard/wizard.py" ] || fail "wizard.py missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/10] Safety backup..."
cp -a tools/project_wizard "$BACKUP/project_wizard"
cp -a "$EXT" "$BACKUP/vscode-extension"
[ -d tests/R3_project_system ] && cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system" || true

echo "[3/10] Rewriting wizard.py cleanly with metadata API..."
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


def template_metadata() -> list[dict[str, str]]:
    return [
        {"id": "console", "label": "Console App", "description": "A minimal PantherLang command-line application."},
        {"id": "web", "label": "Web App", "description": "A PantherLang web application starter."},
        {"id": "api", "label": "API App", "description": "A PantherLang REST/API service starter."},
        {"id": "ai", "label": "AI App", "description": "A PantherLang AI-ready application starter."},
    ]


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

echo "[4/10] Writing template metadata JSON..."
cat > tools/project_wizard/templates.json <<'EOF'
{
  "templates": [
    {"id": "console", "label": "Console App", "description": "A minimal PantherLang command-line application.", "folder": "console_app"},
    {"id": "web", "label": "Web App", "description": "A PantherLang web application starter.", "folder": "web_app"},
    {"id": "api", "label": "API App", "description": "A PantherLang REST/API service starter.", "folder": "api_app"},
    {"id": "ai", "label": "AI App", "description": "A PantherLang AI-ready application starter.", "folder": "ai_app"}
  ]
}
EOF

echo "[5/10] Rewriting VS Code UX implementation..."
cat > "$EXT/src/extension.js" <<'JS'
const vscode = require('vscode');
const cp = require('child_process');
const path = require('path');
const fs = require('fs');

const templates = [
  { id: 'console', label: 'Console App', description: 'Minimal PantherLang command-line application' },
  { id: 'web', label: 'Web App', description: 'PantherLang web application starter' },
  { id: 'api', label: 'API App', description: 'PantherLang REST/API service starter' },
  { id: 'ai', label: 'AI App', description: 'PantherLang AI-ready application starter' }
];

function getWorkspaceRoot() {
  const folders = vscode.workspace.workspaceFolders;
  return folders && folders.length ? folders[0].uri.fsPath : undefined;
}

function runCommand(command, args, cwd) {
  return new Promise((resolve, reject) => {
    cp.execFile(command, args, { cwd }, (error, stdout, stderr) => {
      if (error) reject(new Error(stderr || error.message));
      else resolve(stdout || stderr || '');
    });
  });
}

async function selectDestination() {
  const root = getWorkspaceRoot();
  if (root) {
    const choice = await vscode.window.showQuickPick(
      [
        { label: 'Current Workspace', description: root, value: root },
        { label: 'Choose Folder...', description: 'Select another destination', value: '__choose__' }
      ],
      { placeHolder: 'Choose where to create the PantherLang project' }
    );
    if (!choice) return undefined;
    if (choice.value !== '__choose__') return choice.value;
  }

  const selected = await vscode.window.showOpenDialog({
    canSelectFiles: false,
    canSelectFolders: true,
    canSelectMany: false,
    openLabel: 'Select PantherLang Project Destination'
  });
  return selected && selected.length ? selected[0].fsPath : undefined;
}

function validateProjectName(value) {
  if (!value || !value.trim()) return 'Project name is required';
  if (!/^[A-Za-z0-9_-]+$/.test(value.trim())) return 'Use only letters, numbers, dash, and underscore';
  return null;
}

async function createProject(templateId) {
  let template = templateId;
  if (!template) {
    const picked = await vscode.window.showQuickPick(
      templates.map(t => ({ label: t.label, description: t.description, value: t.id })),
      { placeHolder: 'Select PantherLang project template' }
    );
    if (!picked) return;
    template = picked.value;
  }

  const projectName = await vscode.window.showInputBox({
    prompt: 'PantherLang project name',
    value: template === 'console' ? 'hello-panther' : `hello-${template}`,
    validateInput: validateProjectName
  });
  if (!projectName) return;

  const destination = await selectDestination();
  if (!destination) return;

  const workspaceRoot = getWorkspaceRoot() || destination;
  const scriptCandidates = [
    path.join(workspaceRoot, 'tools', 'project_wizard', 'panther_new.py'),
    path.join(destination, 'tools', 'project_wizard', 'panther_new.py')
  ];
  const script = scriptCandidates.find(fs.existsSync);
  if (!script) {
    vscode.window.showErrorMessage('PantherLang project wizard script not found. Open the PantherLang repository workspace first.');
    return;
  }

  await vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification,
    title: `Creating PantherLang ${template} project`,
    cancellable: false
  }, async () => {
    const output = await runCommand('python3', [script, projectName, '--template', template, '--destination', destination, '--json'], workspaceRoot);
    const data = JSON.parse(output);
    const createdPath = data.destination;
    const open = await vscode.window.showInformationMessage(
      `Created PantherLang ${template} project: ${projectName}`,
      'Open Project',
      'Show Files'
    );
    if (open === 'Open Project') {
      await vscode.commands.executeCommand('vscode.openFolder', vscode.Uri.file(createdPath), { forceNewWindow: false });
    } else if (open === 'Show Files') {
      await vscode.commands.executeCommand('revealFileInOS', vscode.Uri.file(createdPath));
    }
  });
}

async function doctor() {
  const root = getWorkspaceRoot() || process.cwd();
  const terminal = vscode.window.createTerminal('PantherLang Doctor');
  terminal.show();
  terminal.sendText(`cd "${root}" && python3 - <<'PY'\nfrom panther_core.version import get_release_info\nprint(get_release_info())\nPY`);
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
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newProject', () => createProject(undefined)));
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

echo "[6/10] Updating package.json to 1.0.2..."
python3 <<'PY'
from pathlib import Path
import json

pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.2"

contributes = pkg.setdefault("contributes", {})
menus = contributes.setdefault("menus", {})
command_palette = menus.setdefault("commandPalette", [])
for cmd in [
    "pantherlang.newProject",
    "pantherlang.newConsoleProject",
    "pantherlang.newWebProject",
    "pantherlang.newApiProject",
    "pantherlang.newAiProject",
    "pantherlang.doctor",
    "pantherlang.runFile",
]:
    if not any(item.get("command") == cmd for item in command_palette):
        command_palette.append({"command": cmd})
pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ package.json updated to 1.0.2")
PY

echo "[7/10] Creating Part 2 tests..."
cat > tests/R3_project_system/test_r3_batch1_part2_project_wizard_ux.py <<'PY'
import json
from pathlib import Path

from tools.project_wizard.wizard import template_metadata


def test_template_metadata_for_vscode_quickpick():
    metadata = template_metadata()
    ids = [x["id"] for x in metadata]
    assert ids == ["console", "web", "api", "ai"]
    for item in metadata:
        assert item["label"]
        assert item["description"]


def test_vscode_extension_registers_project_wizard_commands():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    assert "pantherlang.newProject" in commands
    assert "pantherlang.newConsoleProject" in commands
    assert "pantherlang.newWebProject" in commands
    assert "pantherlang.newApiProject" in commands
    assert "pantherlang.newAiProject" in commands
    assert pkg["version"] == "1.0.2"


def test_extension_implementation_contains_ux_flow():
    text = Path("vscode-extension/src/extension.js").read_text()
    assert "showQuickPick" in text
    assert "showInputBox" in text
    assert "showOpenDialog" in text
    assert "withProgress" in text
    assert "Open Project" in text
PY

echo "[8/10] Validation and tests..."
python3 -m py_compile tools/project_wizard/__init__.py tools/project_wizard/wizard.py tools/project_wizard/panther_new.py tests/R3_project_system/test_r3_batch1_part2_project_wizard_ux.py
python3 -m pytest tests/R3_project_system -q

echo "[9/10] Rebuild VSIX 1.0.2..."
(
  cd "$EXT"
  rm -f pantherlang-1.0.2*.vsix
  npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t "$EXT"/pantherlang-1.0.2*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX 1.0.2 was not created."
cp "$VSIX" releases/vscode_marketplace/
sha256sum "releases/vscode_marketplace/$(basename "$VSIX")" > "releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[10/10] Writing status/report..."
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
    "part": "2",
    "name": "Project Wizard UX Integration",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.2",
    "runtime_modified": True,
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Part 3 - Project Templates Professionalization"
}
(r3 / "batch1_part2_project_wizard_ux_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART2_PROJECT_WIZARD_UX_INTEGRATION.md" <<EOF
# R3 Batch 1 Part 2 - Project Wizard UX Integration

## Status

PASSED

## Version

PantherLang VS Code Extension 1.0.2

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R3 Batch 1 Part 3 - Project Templates Professionalization.
EOF

cat > "$R3/status_batch1_part2_project_wizard_ux_integration.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "part": "2",
  "status": "PASSED",
  "name": "Project Wizard UX Integration",
  "version": "1.0.2",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R3 Batch 1 Part 3 - Project Templates Professionalization"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 1 Part 2 COMPLETE"
echo "✅ Project Wizard UX Integration READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 3 - Project Templates Professionalization"
echo "============================================================"
