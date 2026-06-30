#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 Final - Developer Experience Release"
echo "============================================================"

ROOT="$(pwd)"
EXT="$ROOT/vscode-extension"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
RELEASES="$ROOT/releases/R3_developer_experience"
STAMP="$(date +%Y%m%d_%H%M%S)"
VERSION="1.1.0"

mkdir -p "$R3" "$REPORTS" "$RELEASES"

fail(){ echo "[R3-B1-FINAL][ERROR] $1" >&2; exit 1; }

echo "[1/12] Checking completed R3 Batch 1 gates..."
for f in \
  "$R3/status_batch1_part1_project_wizard_foundation.json" \
  "$R3/status_batch1_part2_project_wizard_ux_integration.json" \
  "$R3/status_batch1_part3_templates_professionalization.json" \
  "$R3/status_batch1_part4_run_command_integration.json" \
  "$R3/status_batch1_part5_build_command_integration.json" \
  "$R3/status_batch1_part6_debug_launch_integration.json" \
  "$R3/status_batch1_part7_agent_knowledge_pack.json"
do
  [ -f "$f" ] || fail "Missing gate: $f"
done

echo "[2/12] Full regression..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q
python3 -m pytest tests/R3_project_system -q

echo "[3/12] Setting release version $VERSION..."
python3 <<PY
from pathlib import Path
import json

pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "$VERSION"
pkg["description"] = "Official PantherLang language support, project wizard, run/build/debug tooling, and AI agent knowledge pack for Visual Studio Code."
pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ version set:", pkg["version"])
PY

echo "[4/12] Creating final developer experience verification test..."
cat > tests/R3_project_system/test_r3_batch1_final_developer_experience.py <<'PY'
from pathlib import Path
import json
import subprocess
import sys

from tools.project_wizard.wizard import create_project
from tools.project_runner.runner import build_project


def test_r3_batch1_final_full_project_cycle(tmp_path):
    result = create_project("final-cycle", "console", tmp_path)
    project = result.destination

    assert (project / "README.md").exists()
    assert (project / ".vscode" / "tasks.json").exists()
    assert (project / ".vscode" / "launch.json").exists()

    build = build_project(project)
    assert build.ok is True
    assert build.artifact.exists()

    debug = subprocess.run(
        [
            sys.executable,
            "tools/project_runner/panther_debug.py",
            "--project",
            str(project),
            "--json",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(debug.stdout)
    assert data["ok"] is True
    assert data["stage"] == "r3_debug_launch_scaffold"


def test_r3_batch1_final_vscode_commands_present():
    pkg = json.loads(Path("vscode-extension/package.json").read_text())
    commands = {c["command"] for c in pkg["contributes"]["commands"]}

    required = {
        "pantherlang.newProject",
        "pantherlang.runFile",
        "pantherlang.buildProject",
        "pantherlang.debugProject",
        "pantherlang.openAgentGuide",
        "pantherlang.doctor",
    }
    assert required.issubset(commands)
    assert pkg["version"] == "1.1.0"


def test_r3_batch1_final_agent_docs_present():
    assert Path("docs/agent_knowledge/PANTHERLANG_AGENT_GUIDE.md").exists()
    assert Path(".github/copilot/instructions.md").exists()
PY

echo "[5/12] Final R3 tests..."
python3 -m py_compile tests/R3_project_system/test_r3_batch1_final_developer_experience.py
python3 -m pytest tests/R3_project_system -q

echo "[6/12] Build final VSIX $VERSION..."
(
  cd "$EXT"
  rm -f "pantherlang-$VERSION"*.vsix
  npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t "$EXT"/pantherlang-"$VERSION"*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX $VERSION was not created."
cp "$VSIX" releases/vscode_marketplace/
sha256sum "releases/vscode_marketplace/$(basename "$VSIX")" > "releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[7/12] Verify VSIX content..."
python3 <<PY
from pathlib import Path
import zipfile, json
vsix = Path("releases/vscode_marketplace/$(basename "$VSIX")")
with zipfile.ZipFile(vsix) as z:
    names = set(z.namelist())
    assert "extension/package.json" in names
    pkg = json.loads(z.read("extension/package.json").decode())
    assert pkg["version"] == "$VERSION"
    assert any(n.endswith("extension.js") for n in names)
print("✅ VSIX verified:", vsix)
PY

echo "[8/12] Creating release archive..."
ARCHIVE="$RELEASES/PantherLang_R3_Batch1_Developer_Experience_v${VERSION}_${STAMP}.tar.gz"
tar -czf "$ARCHIVE" \
  .panther/R3_production_developer_experience \
  reports/R3_project_system \
  project_templates \
  tools/project_wizard \
  tools/project_runner \
  docs/agent_knowledge \
  docs/examples \
  .github/copilot \
  tests/R3_project_system \
  vscode-extension/package.json \
  vscode-extension/src \
  vscode-extension/out \
  "releases/vscode_marketplace/$(basename "$VSIX")"

sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

echo "[9/12] Writing final manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r3 = root / ".panther/R3_production_developer_experience"
vsix = root / "releases/vscode_marketplace" / "$(basename "$VSIX")"
archive = Path("$ARCHIVE")

manifest = {
    "ok": True,
    "phase": "R3",
    "batch": "1",
    "status": "COMPLETE",
    "name": "Developer Experience Release",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "$VERSION",
    "runtime_modified": True,
    "completed_parts": [
        "Project Wizard Foundation",
        "Project Wizard UX Integration",
        "Project Templates Professionalization",
        "Run Command Integration",
        "Build Command Integration",
        "Debug Launch Integration",
        "Agent Knowledge Pack"
    ],
    "developer_cycle": [
        "New Project",
        "Edit PantherLang source",
        "Run Current File",
        "Build Project",
        "Debug Project",
        "Open Agent Guide"
    ],
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "archive": archive.relative_to(root).as_posix(),
    "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
    "next": "R3 Batch 2 - Compiler Runtime"
}
(r3 / "R3_BATCH1_FINAL_DEVELOPER_EXPERIENCE_MANIFEST.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ final manifest written")
PY

echo "[10/12] Writing final report..."
cat > "$REPORTS/R3_BATCH1_FINAL_DEVELOPER_EXPERIENCE_RELEASE.md" <<EOF
# R3 Batch 1 Final - Developer Experience Release

## Status

COMPLETE

## Version

PantherLang VS Code Extension $VERSION

## Completed

- Project Wizard Foundation
- Project Wizard UX Integration
- Project Templates Professionalization
- Run Command Integration
- Build Command Integration
- Debug Launch Integration
- Agent Knowledge Pack

## Developer Cycle Now Available

1. Create a PantherLang project.
2. Open/edit \`.panther\` source files.
3. Run current file.
4. Build project.
5. Start debug launch.
6. Open Agent Guide.

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Archive

\`$ARCHIVE\`

## Next

R3 Batch 2 - Compiler Runtime.
EOF

echo "[11/12] Git status snapshot..."
git status --short > "$R3/git_status_after_R3_batch1_final_${STAMP}.txt" || true

echo "[12/12] Writing status..."
cat > "$R3/status_batch1_final_developer_experience_release.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "status": "COMPLETE",
  "name": "Developer Experience Release",
  "version": "$VERSION",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "archive": "$ARCHIVE",
  "next": "R3 Batch 2 - Compiler Runtime"
}
EOF

echo "============================================================"
echo "✅ R3 BATCH 1 FINAL COMPLETE"
echo "✅ Developer Experience Release READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Archive: $ARCHIVE"
echo "Next: R3 Batch 2 - Compiler Runtime"
echo "============================================================"
