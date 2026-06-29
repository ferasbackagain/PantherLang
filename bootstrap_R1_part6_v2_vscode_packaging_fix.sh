#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R1"
echo " Product Unification"
echo " Part 6 v2 - VS Code Extension Packaging Fix"
echo "============================================================"

ROOT="$(pwd)"
R1="$ROOT/.panther/R1_product_unification"
REPORTS="$ROOT/reports/R1_product_unification"
EXT="$ROOT/vscode-extension"
BACKUP="$ROOT/.panther/backups/R1_part6_v2_vscode_packaging_fix_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R1" "$REPORTS" "$BACKUP"

fail(){ echo "[R1-P6-v2][ERROR] $1" >&2; exit 1; }

echo "[1/9] Pre-flight..."
[ -d "$EXT" ] || fail "vscode-extension missing"
[ -f "$EXT/package.json" ] || fail "package.json missing"

echo "[2/9] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"

echo "[3/9] Fixing package.json icon path + version..."
python3 <<'PY'
from pathlib import Path
import json

pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())

pkg["version"] = "1.0.0"
pkg["icon"] = "assets/pantherlang-icon.png"
pkg["galleryBanner"] = {"color": "#0B1F3A", "theme": "dark"}

pkg.setdefault("publisher", "pantherlang")
pkg.setdefault("displayName", "PantherLang")
pkg["description"] = "Official PantherLang language support, developer tooling, and debug adapter integration for Visual Studio Code."

pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ package.json fixed: icon=assets/pantherlang-icon.png version=1.0.0")
PY

echo "[4/9] Ensuring icon and LICENSE exist inside vscode-extension..."
mkdir -p "$EXT/assets"

python3 <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

icon = Path("vscode-extension/assets/pantherlang-icon.png")
W = H = 256
img = Image.new("RGBA", (W, H), (6, 18, 36, 255))
draw = ImageDraw.Draw(img)
draw.rounded_rectangle((16, 16, 240, 240), radius=42, fill=(8, 31, 58, 255), outline=(60, 135, 220, 255), width=5)
draw.rounded_rectangle((36, 36, 220, 220), radius=32, outline=(25, 75, 130, 255), width=3)
try:
    font = ImageFont.truetype("DejaVuSans-Bold.ttf", 112)
    small = ImageFont.truetype("DejaVuSans-Bold.ttf", 28)
except Exception:
    font = None
    small = None
bbox = draw.textbbox((0,0), "P", font=font)
draw.text(((W-(bbox[2]-bbox[0]))/2, 62), "P", font=font, fill=(235, 245, 255, 255))
draw.text((57, 184), "LANG", font=small, fill=(100, 170, 255, 255))
img.save(icon)
print("✅ icon regenerated")
PY

cat > "$EXT/LICENSE" <<'EOF'
Copyright (c) Feras Khatib.

All rights reserved unless a separate license is provided by the project owner.
EOF

echo "[5/9] Validating extension assets..."
python3 <<'PY'
from pathlib import Path
import json

ext = Path("vscode-extension")
pkg = json.loads((ext / "package.json").read_text())
icon = ext / pkg["icon"]

assert pkg["version"] == "1.0.0", pkg["version"]
assert pkg["icon"] == "assets/pantherlang-icon.png", pkg["icon"]
assert icon.exists(), icon
assert (ext / "LICENSE").exists()
assert (ext / "README.md").exists()
assert (ext / "CHANGELOG.md").exists()

print("✅ extension assets valid")
PY

echo "[6/9] Rebuilding VSIX..."
rm -f "$EXT"/*.vsix
(
  cd "$EXT"
  yes y | npx --yes @vscode/vsce package
)

echo "[7/9] Copying VSIX to releases..."
mkdir -p "$ROOT/releases/vscode_marketplace"
VSIX="$(ls -t "$EXT"/*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX was not produced"

cp "$VSIX" "$ROOT/releases/vscode_marketplace/$(basename "$VSIX")"
sha256sum "$ROOT/releases/vscode_marketplace/$(basename "$VSIX")" > "$ROOT/releases/vscode_marketplace/$(basename "$VSIX").sha256"

echo "[8/9] Writing report + manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r1 = root / ".panther" / "R1_product_unification"
vsix = Path("$VSIX")
release_vsix = root / "releases" / "vscode_marketplace" / vsix.name

manifest = {
    "ok": True,
    "phase": "R1",
    "part": "6-v2",
    "name": "VS Code Extension Packaging Fix",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.0",
    "icon": "assets/pantherlang-icon.png",
    "vsix": release_vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(release_vsix.read_bytes()).hexdigest(),
    "runtime_modified": True,
    "next": "R1 Part 7 - Release Verification"
}
(r1 / "part6_v2_vscode_packaging_fix_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ VSIX:", vsix.name)
PY

cat > "$REPORTS/R1_PART6_V2_VSCODE_PACKAGING_FIX.md" <<EOF
# R1 Part 6 v2 - VS Code Extension Packaging Fix

## Status

PASSED

## Fixed

- Corrected Marketplace icon path to \`assets/pantherlang-icon.png\`
- Ensured dark-blue icon exists
- Ensured LICENSE exists inside \`vscode-extension/\`
- Rebuilt VSIX successfully

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R1 Part 7 - Release Verification.
EOF

echo "[9/9] Writing status..."
cat > "$R1/status_part6_vscode_extension_alignment.json" <<EOF
{
  "ok": true,
  "phase": "R1",
  "part": "6",
  "status": "PASSED",
  "name": "VS Code Extension Alignment",
  "version": "1.0.0",
  "icon": "assets/pantherlang-icon.png",
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "runtime_modified": true,
  "next": "R1 Part 7 - Release Verification"
}
EOF

echo "============================================================"
echo "✅ R1 Part 6 COMPLETE"
echo "✅ VSIX FIXED AND READY: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R1 Part 7 - Release Verification"
echo "============================================================"
