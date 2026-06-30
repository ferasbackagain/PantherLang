#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 Part 3 v2 - Version-Aware Test Fix"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part3_v2_version_test_fix_$(date +%Y%m%d_%H%M%S)"
EXT="$ROOT/vscode-extension"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P3-v2][ERROR] $1" >&2; exit 1; }

echo "[1/9] Pre-flight..."
[ -f "$R3/status_batch1_part2_project_wizard_ux_integration.json" ] || fail "Run R3 Batch 1 Part 2 first."
[ -f "tests/R3_project_system/test_r3_batch1_part2_project_wizard_ux.py" ] || fail "Part 2 UX test missing."
[ -f "$EXT/package.json" ] || fail "package.json missing."

echo "[2/9] Safety backup..."
cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system"
cp -a "$EXT" "$BACKUP/vscode-extension"
cp -a project_templates "$BACKUP/project_templates" 2>/dev/null || true

echo "[3/9] Making Part 2 test version-aware..."
python3 <<'PY'
from pathlib import Path

p = Path("tests/R3_project_system/test_r3_batch1_part2_project_wizard_ux.py")
text = p.read_text()
text = text.replace('assert pkg["version"] == "1.0.2"', 'assert pkg["version"] >= "1.0.2"')
p.write_text(text)
print("✅ Part 2 version assertion relaxed for forward-compatible R3 releases")
PY

echo "[4/9] Ensuring package version is 1.0.3..."
python3 <<'PY'
from pathlib import Path
import json
pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.3"
pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ package.json version:", pkg["version"])
PY

echo "[5/9] Re-run R3 tests..."
python3 -m py_compile tools/project_wizard/__init__.py tools/project_wizard/wizard.py tools/project_wizard/panther_new.py
python3 -m pytest tests/R3_project_system -q

echo "[6/9] Rebuild VSIX 1.0.3..."
(
  cd "$EXT"
  rm -f pantherlang-1.0.3*.vsix
  npx --yes @vscode/vsce package --no-dependencies
)

mkdir -p releases/vscode_marketplace
VSIX="$(ls -t "$EXT"/pantherlang-1.0.3*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX 1.0.3 was not created."
cp "$VSIX" releases/vscode_marketplace/
sha256sum "releases/vscode_marketplace/$(basename "$VSIX")" > "releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[7/9] Final smoke verification..."
python3 - <<PY
from pathlib import Path
import json, zipfile
vsix = Path("releases/vscode_marketplace/$(basename "$VSIX")")
assert vsix.exists()
with zipfile.ZipFile(vsix) as z:
    pkg = json.loads(z.read("extension/package.json").decode())
    assert pkg["version"] == "1.0.3"
print("✅ VSIX package version verified:", vsix)
PY

echo "[8/9] Writing manifest/report/status..."
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
    "part": "3-v2",
    "name": "Project Templates Professionalization Version-Aware Test Fix",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.3",
    "runtime_modified": True,
    "fix": "Part 2 UX test now accepts forward R3 versions >= 1.0.2",
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Part 4 - Run Command Integration"
}
(r3 / "batch1_part3_v2_version_test_fix_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART3_V2_VERSION_TEST_FIX.md" <<EOF
# R3 Batch 1 Part 3 v2 - Version-Aware Test Fix

## Status

PASSED

## Fixed

The previous Part 2 test expected exactly \`1.0.2\`, but Part 3 correctly bumps the extension to \`1.0.3\`.

The test now accepts forward-compatible R3 versions:

\`\`\`python
assert pkg["version"] >= "1.0.2"
\`\`\`

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R3 Batch 1 Part 4 - Run Command Integration.
EOF

cat > "$R3/status_batch1_part3_templates_professionalization.json" <<EOF
{
  "ok": true,
  "phase": "R3",
  "batch": "1",
  "part": "3",
  "status": "PASSED",
  "name": "Project Templates Professionalization",
  "version": "1.0.3",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R3 Batch 1 Part 4 - Run Command Integration"
}
EOF

echo "[9/9] Done."
echo "============================================================"
echo "✅ R3 Batch 1 Part 3 COMPLETE"
echo "✅ Project Templates Professionalization READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 4 - Run Command Integration"
echo "============================================================"
