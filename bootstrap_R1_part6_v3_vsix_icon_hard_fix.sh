#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R1"
echo " Product Unification"
echo " Part 6 v3 - VSIX Icon Path Hard Fix"
echo "============================================================"

ROOT="$(pwd)"
R1="$ROOT/.panther/R1_product_unification"
REPORTS="$ROOT/reports/R1_product_unification"
EXT="$ROOT/vscode-extension"
BACKUP="$ROOT/.panther/backups/R1_part6_v3_vsix_icon_hard_fix_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R1" "$REPORTS" "$BACKUP"

fail(){ echo "[R1-P6-v3][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight..."
[ -d "$EXT" ] || fail "vscode-extension missing"
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing"

echo "[2/10] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"

echo "[3/10] Inspecting package.json icon fields before fix..."
grep -R '"icon"' -n "$EXT" --exclude='*.vsix' || true

echo "[4/10] Hard-fixing package.json + files/include rules..."
python3 <<'PY'
from pathlib import Path
import json

ext = Path("vscode-extension")
pkg_path = ext / "package.json"
pkg = json.loads(pkg_path.read_text())

# Force the correct path relative to vscode-extension/package.json.
pkg["version"] = "1.0.0"
pkg["icon"] = "assets/pantherlang-icon.png"
pkg["publisher"] = pkg.get("publisher") or "pantherlang"
pkg["displayName"] = pkg.get("displayName") or "PantherLang"
pkg["description"] = "Official PantherLang language support, developer tooling, and debug adapter integration for Visual Studio Code."
pkg["galleryBanner"] = {"color": "#0B1F3A", "theme": "dark"}

# If a package "files" allowlist exists, ensure assets/docs are included.
files = pkg.get("files")
if isinstance(files, list):
    for item in ["assets/**", "README.md", "CHANGELOG.md", "LICENSE", "package.json"]:
        if item not in files:
            files.append(item)
    pkg["files"] = files

pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ package.json icon:", pkg["icon"])
PY

echo "[5/10] Ensuring icon exists exactly where package.json points..."
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
print("✅ icon exists:", icon, icon.exists())
PY

cat > "$EXT/LICENSE" <<'EOF'
Copyright (c) Feras Khatib.

All rights reserved unless a separate license is provided by the project owner.
EOF

[ -f "$EXT/README.md" ] || cat > "$EXT/README.md" <<'EOF'
# PantherLang

Official PantherLang language support, developer tooling, and debug adapter integration for Visual Studio Code.
EOF

[ -f "$EXT/CHANGELOG.md" ] || cat > "$EXT/CHANGELOG.md" <<'EOF'
# Changelog

## 1.0.0

- PantherLang v1.0.0 product alignment.
EOF

echo "[6/10] Cleaning stale VSIX and checking active package.json..."
rm -f "$EXT"/*.vsix

node <<'NODE'
const fs = require("fs");
const path = require("path");
const pkg = JSON.parse(fs.readFileSync("vscode-extension/package.json", "utf8"));
console.log("active package icon:", pkg.icon);
console.log("active package version:", pkg.version);
const iconPath = path.join("vscode-extension", pkg.icon);
if (pkg.icon !== "assets/pantherlang-icon.png") {
  throw new Error("icon path not fixed: " + pkg.icon);
}
if (!fs.existsSync(iconPath)) {
  throw new Error("icon file missing: " + iconPath);
}
if (!fs.existsSync("vscode-extension/LICENSE")) {
  throw new Error("LICENSE missing");
}
NODE

echo "[7/10] Checking .vscodeignore does not exclude assets/LICENSE..."
if [ -f "$EXT/.vscodeignore" ]; then
  cp "$EXT/.vscodeignore" "$BACKUP/.vscodeignore.before"
  # Remove broad exclusions that break the icon/license package.
  sed -i '/^assets$/d;/^assets\//d;/^assets\/\*\*/d;/^LICENSE$/d;/^\*\.png$/d' "$EXT/.vscodeignore"
fi

echo "[8/10] Rebuilding VSIX from extension root..."
(
  cd "$EXT"
  echo "PWD for vsce: $(pwd)"
  echo "package icon from cwd:"
  node -e "const p=require('./package.json'); console.log(p.icon); require('fs').accessSync(p.icon); console.log('icon access OK')"
  npx --yes @vscode/vsce package --no-dependencies
)

echo "[9/10] Copying VSIX and writing status..."
mkdir -p "$ROOT/releases/vscode_marketplace"
VSIX="$(ls -t "$EXT"/*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX was not created"

cp "$VSIX" "$ROOT/releases/vscode_marketplace/$(basename "$VSIX")"
sha256sum "$ROOT/releases/vscode_marketplace/$(basename "$VSIX")" > "$ROOT/releases/vscode_marketplace/$(basename "$VSIX").sha256"

cat > "$REPORTS/R1_PART6_V3_VSIX_ICON_HARD_FIX.md" <<EOF
# R1 Part 6 v3 - VSIX Icon Path Hard Fix

## Status

PASSED

## Fixed

- Forced \`package.json.icon\` to \`assets/pantherlang-icon.png\`
- Regenerated dark-blue PantherLang icon
- Ensured LICENSE exists
- Removed .vscodeignore rules that could exclude icon/license
- Rebuilt VSIX

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R1 Part 7 - Release Verification.
EOF

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

echo "[10/10] Done."
echo "============================================================"
echo "✅ R1 Part 6 COMPLETE"
echo "✅ VSIX FIXED AND READY: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R1 Part 7 - Release Verification"
echo "============================================================"
