#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 - Project System"
echo " Part 5 - Build Command Integration"
echo "============================================================"

ROOT="$(pwd)"
EXT="$ROOT/vscode-extension"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part5_build_command_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P5][ERROR] $1" >&2; exit 1; }

echo "[1/12] Pre-flight gates..."
[ -d ".git" ] || fail "Run from PantherLang project root."
[ -f "$R3/status_batch1_part4_run_command_integration.json" ] || fail "Run R3 Batch 1 Part 4 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/12] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"
[ -d tools/project_runner ] && cp -a tools/project_runner "$BACKUP/project_runner" || true
[ -d tests/R3_project_system ] && cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system" || true

echo "[3/12] Baseline tests..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q
python3 -m pytest tests/R3_project_system -q

echo "[4/12] Creating Panther project runner/build engine scaffold..."
mkdir -p tools/project_runner

cat > tools/project_runner/__init__.py <<'PY'
from .runner import build_project, run_project, read_project_manifest

__all__ = ["build_project", "run_project", "read_project_manifest"]
PY

cat > tools/project_runner/runner.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import json
import re


@dataclass(frozen=True)
class ProjectManifest:
    root: Path
    name: str
    kind: str
    main: Path


@dataclass(frozen=True)
class BuildResult:
    ok: bool
    project: str
    output_dir: Path
    artifact: Path
    files_written: int


def _extract_toml_string(text: str, key: str, default: str = "") -> str:
    match = re.search(rf"^\s*{re.escape(key)}\s*=\s*\"([^\"]*)\"", text, re.MULTILINE)
    return match.group(1) if match else default


def read_project_manifest(project_root: str | Path = ".") -> ProjectManifest:
    root = Path(project_root).resolve()
    manifest = root / "panther.toml"
    if not manifest.exists():
        raise FileNotFoundError(f"panther.toml not found in {root}")

    text = manifest.read_text(encoding="utf-8")
    name = _extract_toml_string(text, "name", root.name)
    kind = _extract_toml_string(text, "type", "console")
    main_raw = _extract_toml_string(text, "main", "src/main.panther")
    main = (root / main_raw).resolve()

    return ProjectManifest(root=root, name=name, kind=kind, main=main)


def build_project(project_root: str | Path = ".", output_dir: str | Path | None = None) -> BuildResult:
    manifest = read_project_manifest(project_root)
    if not manifest.main.exists():
        raise FileNotFoundError(f"main PantherLang file not found: {manifest.main}")

    out_dir = Path(output_dir).resolve() if output_dir else manifest.root / "build"
    out_dir.mkdir(parents=True, exist_ok=True)

    source = manifest.main.read_text(encoding="utf-8")
    artifact = out_dir / f"{manifest.name}.build.json"
    artifact.write_text(json.dumps({
        "ok": True,
        "project": manifest.name,
        "type": manifest.kind,
        "main": manifest.main.relative_to(manifest.root).as_posix(),
        "source_bytes": len(source.encode("utf-8")),
        "stage": "r3_build_scaffold",
        "note": "Compiler backend integration comes next; this artifact validates project build wiring."
    }, indent=2), encoding="utf-8")

    return BuildResult(ok=True, project=manifest.name, output_dir=out_dir, artifact=artifact, files_written=1)


def run_project(project_root: str | Path = ".") -> str:
    result = build_project(project_root)
    return f"PantherLang run scaffold OK: {result.project} -> {result.artifact}"
PY

cat > tools/project_runner/panther_build.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from tools.project_runner.runner import build_project


def main() -> int:
    parser = argparse.ArgumentParser(description="Build a PantherLang project.")
    parser.add_argument("--project", default=".", help="Project root containing panther.toml")
    parser.add_argument("--output", default=None, help="Build output directory")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    result = build_project(args.project, args.output)
    if args.json:
        print(json.dumps({
            "ok": result.ok,
            "project": result.project,
            "output_dir": str(result.output_dir),
            "artifact": str(result.artifact),
            "files_written": result.files_written,
        }, indent=2))
    else:
        print(f"✅ Built PantherLang project: {result.project}")
        print(f"Artifact: {result.artifact}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
chmod +x tools/project_runner/panther_build.py

echo "[5/12] Adding VS Code Build command implementation..."
cat > "$EXT/src/build_command.js" <<'JS'
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

async function buildProject() {
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

  const repoRunner = path.join(root, 'tools', 'project_runner', 'panther_build.py');
  const fallbackRunner = path.join(__dirname, '..', '..', 'tools', 'project_runner', 'panther_build.py');
  const runner = fs.existsSync(repoRunner) ? repoRunner : fallbackRunner;

  const terminal = vscode.window.createTerminal('PantherLang Build');
  terminal.show();

  await vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification,
    title: 'Building PantherLang project',
    cancellable: false
  }, async () => {
    if (fs.existsSync(runner)) {
      const output = await execFile('python3', [runner, '--project', root, '--json'], root);
      terminal.sendText(`echo '${output.replace(/'/g, "'\\''")}'`);
      vscode.window.showInformationMessage('PantherLang build completed.');
    } else {
      terminal.sendText('panther build');
      vscode.window.showInformationMessage('PantherLang build command sent to terminal.');
    }
  });
}

module.exports = { buildProject };
JS

echo "[6/12] Wiring extension.js and package.json..."
python3 <<'PY'
from pathlib import Path
import json

ext = Path("vscode-extension")
extension_js = ext / "src" / "extension.js"
text = extension_js.read_text()

if "build_command" not in text:
    text = "const {buildProject}=require('./build_command');\n" + text

if "pantherlang.buildProject" not in text:
    marker = "context.subscriptions.push(vscode.commands.registerCommand('pantherlang.runFile', runFile));"
    replacement = marker + "\n  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.buildProject', buildProject));"
    text = text.replace(marker, replacement)

extension_js.write_text(text)
(ext / "out" / "extension.js").write_text(text)
(ext / "out" / "build_command.js").write_text((ext / "src" / "build_command.js").read_text())

pkg_path = ext / "package.json"
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.5"

contributes = pkg.setdefault("contributes", {})
commands = contributes.setdefault("commands", [])
if not any(c.get("command") == "pantherlang.buildProject" for c in commands):
    commands.append({"command": "pantherlang.buildProject", "title": "PantherLang: Build Project"})

menus = contributes.setdefault("menus", {})
palette = menus.setdefault("commandPalette", [])
if not any(c.get("command") == "pantherlang.buildProject" for c in palette):
    palette.append({"command": "pantherlang.buildProject"})

activation = set(pkg.get("activationEvents") or [])
activation.add("onCommand:pantherlang.buildProject")
pkg["activationEvents"] = sorted(activation)

pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ Build command wired; version 1.0.5")
PY

echo "[7/12] Updating template tasks to use Build command consistency..."
for t in console_app web_app api_app ai_app; do
python3 <<PY
from pathlib import Path
p=Path("project_templates/$t/.vscode/tasks.json")
text=p.read_text()
assert "PantherLang: Build" in text
assert "panther build" in text
PY
done

echo "[8/12] Creating Part 5 tests..."
cat > tests/R3_project_system/test_r3_batch1_part5_build_command.py <<'PY'
from pathlib import Path
import json
import subprocess
import sys

from tools.project_wizard.wizard import create_project
from tools.project_runner.runner import build_project, read_project_manifest


def test_build_runner_creates_artifact(tmp_path):
    result = create_project("build-demo", "console", tmp_path)
    build = build_project(result.destination)
    assert build.ok is True
    assert build.artifact.exists()
    data = json.loads(build.artifact.read_text())
    assert data["project"] == "build-demo"
    assert data["stage"] == "r3_build_scaffold"


def test_build_cli_json_output(tmp_path):
    result = create_project("build-cli-demo", "api", tmp_path)
    proc = subprocess.run(
        [
            sys.executable,
            "tools/project_runner/panther_build.py",
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
    assert data["project"] == "build-cli-demo"
    assert Path(data["artifact"]).exists()


def test_vscode_build_command_registered():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}
    assert "pantherlang.buildProject" in commands
    assert pkg["version"] == "1.0.5"
    src = Path("vscode-extension/src/build_command.js").read_text()
    assert "panther_build.py" in src
    assert "Building PantherLang project" in src
PY

echo "[9/12] Validation and full R3 tests..."
python3 -m py_compile tools/project_runner/__init__.py tools/project_runner/runner.py tools/project_runner/panther_build.py tests/R3_project_system/test_r3_batch1_part5_build_command.py
python3 -m pytest tests/R3_project_system -q

echo "[10/12] Build VSIX 1.0.5..."
(
  cd "$EXT"
  rm -f pantherlang-1.0.5*.vsix
  npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t "$EXT"/pantherlang-1.0.5*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX 1.0.5 was not created."
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
    "part": "5",
    "name": "Build Command Integration",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.5",
    "runtime_modified": True,
    "features": [
        "project_runner_build_scaffold",
        "panther_build_cli",
        "vscode_build_project_command",
        "build_artifact_json",
        "vsix_1_0_5"
    ],
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Part 6 - Debug Launch Integration"
}
(r3 / "batch1_part5_build_command_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART5_BUILD_COMMAND_INTEGRATION.md" <<EOF
# R3 Batch 1 Part 5 - Build Command Integration

## Status

PASSED

## Version

PantherLang VS Code Extension 1.0.5

## Added

- Project build runner scaffold
- \`tools/project_runner/panther_build.py\`
- VS Code command: \`PantherLang: Build Project\`
- Build artifact generation under \`build/\`
- Build integration tests
- VSIX 1.0.5

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R3 Batch 1 Part 6 - Debug Launch Integration.
EOF

echo "[12/12] Writing status..."
cat > "$R3/status_batch1_part5_build_command_integration.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "part": "5",
  "status": "PASSED",
  "name": "Build Command Integration",
  "version": "1.0.5",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R3 Batch 1 Part 6 - Debug Launch Integration"
}
EOF

echo "============================================================"
echo "✅ R3 Batch 1 Part 5 COMPLETE"
echo "✅ Build Command Integration READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 6 - Debug Launch Integration"
echo "============================================================"
