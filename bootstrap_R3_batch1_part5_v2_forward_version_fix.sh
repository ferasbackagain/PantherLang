#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R3"
echo " Batch 1 Part 5 v2 - Forward Version Test Fix"
echo "============================================================"

ROOT="$(pwd)"
R3="$ROOT/.panther/R3_production_developer_experience"
REPORTS="$ROOT/reports/R3_project_system"
BACKUP="$ROOT/.panther/backups/R3_batch1_part5_v2_forward_version_fix_$(date +%Y%m%d_%H%M%S)"
EXT="$ROOT/vscode-extension"

mkdir -p "$R3" "$REPORTS" "$BACKUP"

fail(){ echo "[R3-B1-P5-v2][ERROR] $1" >&2; exit 1; }

echo "[1/8] Pre-flight..."
[ -f "$R3/status_batch1_part4_run_command_integration.json" ] || fail "Run R3 Batch 1 Part 4 first."
[ -f "tests/R3_project_system/test_r3_batch1_part4_run.py" ] || fail "Part 4 test missing."
[ -f "$EXT/package.json" ] || fail "package.json missing."

echo "[2/8] Safety backup..."
cp -a tests/R3_project_system "$BACKUP/tests_R3_project_system"
cp -a "$EXT" "$BACKUP/vscode-extension"
[ -d tools/project_runner ] && cp -a tools/project_runner "$BACKUP/project_runner" || true

echo "[3/8] Making Part 4 version test forward-compatible..."
python3 <<'PY'
from pathlib import Path

p = Path("tests/R3_project_system/test_r3_batch1_part4_run.py")
text = p.read_text()
text = text.replace('assert pkg["version"]=="1.0.4"', 'assert pkg["version"]>="1.0.4"')
text = text.replace('assert pkg["version"] == "1.0.4"', 'assert pkg["version"] >= "1.0.4"')
p.write_text(text)
print("✅ Part 4 test now accepts forward R3 versions >= 1.0.4")
PY

echo "[4/8] Ensuring package version is 1.0.5..."
python3 <<'PY'
from pathlib import Path
import json
pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())
pkg["version"] = "1.0.5"
pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ package.json version:", pkg["version"])
PY

echo "[5/8] Running full R3 project-system tests..."
python3 -m py_compile \
  tools/project_runner/__init__.py \
  tools/project_runner/runner.py \
  tools/project_runner/panther_build.py \
  tests/R3_project_system/test_r3_batch1_part5_build_command.py

python3 -m pytest tests/R3_project_system -q

echo "[6/8] Rebuild VSIX 1.0.5..."
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

echo "[7/8] Writing manifest/report/status..."
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
    "part": "5-v2",
    "name": "Build Command Integration Forward Version Fix",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.5",
    "runtime_modified": True,
    "fix": "Part 4 run-command test now accepts forward R3 versions >= 1.0.4",
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "next": "R3 Batch 1 Part 6 - Debug Launch Integration"
}
(r3 / "batch1_part5_v2_forward_version_fix_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R3_BATCH1_PART5_V2_FORWARD_VERSION_FIX.md" <<EOF
# R3 Batch 1 Part 5 v2 - Forward Version Test Fix

## Status

PASSED

## Fixed

Part 4 test expected exactly \`1.0.4\`, while Part 5 correctly bumps to \`1.0.5\`.

It now accepts forward R3 versions.

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R3 Batch 1 Part 6 - Debug Launch Integration.
EOF

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

echo "[8/8] Done."
echo "============================================================"
echo "✅ R3 Batch 1 Part 5 COMPLETE"
echo "✅ Build Command Integration READY"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R3 Batch 1 Part 6 - Debug Launch Integration"
echo "============================================================"
