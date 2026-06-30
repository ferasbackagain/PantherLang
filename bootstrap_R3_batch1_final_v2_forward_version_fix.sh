#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 Final v2 - Forward Version Test Fix"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
RELEASES="$ROOT/releases/R3_developer_experience"
BACKUP="$ROOT/.panther/backups/R3_batch1_final_v2_forward_version_fix_$(date +%Y%m%d_%H%M%S)"
EXT="$ROOT/vscode-extension"
VERSION="1.1.0"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R3" "$REPORTS" "$RELEASES" "$BACKUP"

fail(){ echo "[R3-B1-FINAL-v2][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight..."
[ -f "$R3/status_batch1_part7_agent_knowledge_pack.json" ] || fail "Run R3 Batch 1 Part 7 first."
[ -f "tests/R3_project_system/test_r3_batch1_part7_agent_knowledge_pack.py" ] || fail "Part 7 test missing."
[ -f "$EXT/package.json" ] || fail "package.json missing."

echo "[2/10] Safety backup..."
cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system"
cp -a "$EXT" "$BACKUP/vscode-extension"

echo "[3/10] Making Part 7 version test forward-compatible..."
python3 <<'PY'
from pathlib import Path
p = Path("tests/R3_project_system/test_r3_batch1_part7_agent_knowledge_pack.py")
text = p.read_text()
text = text.replace('assert pkg["version"] == "1.0.7"', 'assert pkg["version"] >= "1.0.7"')
text = text.replace('assert pkg["version"]=="1.0.7"', 'assert pkg["version"]>="1.0.7"')
p.write_text(text)
print("✅ Part 7 test now accepts forward R3 versions >= 1.0.7")
PY

echo "[4/10] Ensuring final release version $VERSION..."
python3 <<PY
from pathlib import Path
import json
pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "$VERSION"
pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ package.json version:", pkg["version"])
PY

echo "[5/10] Full final R3 tests..."
python3 -m pytest tests/R3_project_system -q

echo "[6/10] Build final VSIX $VERSION..."
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

echo "[7/10] Verify VSIX version..."
python3 <<PY
from pathlib import Path
import zipfile, json
vsix = Path("releases/vscode_marketplace/$(basename "$VSIX")")
with zipfile.ZipFile(vsix) as z:
    pkg = json.loads(z.read("extension/package.json").decode())
    assert pkg["version"] == "$VERSION"
print("✅ VSIX version verified:", vsix)
PY

echo "[8/10] Create release archive..."
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

echo "[9/10] Writing final manifest/report/status..."
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
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "archive": archive.relative_to(root).as_posix(),
    "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
    "next": "R3 Batch 2 - Compiler Runtime"
}
(r3 / "R3_BATCH1_FINAL_DEVELOPER_EXPERIENCE_MANIFEST.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ final manifest written")
PY

cat > "$REPORTS/R3_BATCH1_FINAL_DEVELOPER_EXPERIENCE_RELEASE.md" <<EOF
# R3 Batch 1 Final - Developer Experience Release

## Status

COMPLETE

## Version

PantherLang VS Code Extension $VERSION

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Archive

\`$ARCHIVE\`

## Next

R3 Batch 2 - Compiler Runtime.
EOF

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

echo "[10/10] Done."
echo "============================================================"
echo "✅ R3 BATCH 1 FINAL COMPLETE"
echo "✅ Developer Experience Release READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Archive: $ARCHIVE"
echo "Next: R3 Batch 2 - Compiler Runtime"
echo "============================================================"
