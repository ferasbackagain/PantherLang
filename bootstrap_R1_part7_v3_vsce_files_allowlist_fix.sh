#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R1"
echo " Product Unification"
echo " Part 7 v3 - VSCE Files Allowlist Fix"
echo "============================================================"

ROOT="$(pwd)"
R1="$ROOT/.panther/R1_product_unification"
REPORTS="$ROOT/reports/R1_product_unification"
EXT="$ROOT/vscode-extension"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
BACKUP="$ROOT/.panther/backups/R1_part7_v3_vsce_files_allowlist_fix_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R1" "$REPORTS" "$BACKUP" "$VSIX_DIR"

fail(){ echo "[R1-P7-v3][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight gates..."
[ -f "$R1/status_part6_vscode_extension_alignment.json" ] || fail "Run R1 Part 6 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/10] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"

echo "[3/10] Removing unused package.json files patterns..."
python3 <<'PY'
from pathlib import Path
import json

ext = Path("vscode-extension")
pkg_path = ext / "package.json"
pkg = json.loads(pkg_path.read_text())

pkg["version"] = "1.0.0"
pkg["icon"] = "assets/pantherlang-icon.png"
pkg["galleryBanner"] = {"color": "#0B1F3A", "theme": "dark"}

# Build a conservative allowlist containing only patterns that exist or are required Marketplace docs/assets.
required = [
    "package.json",
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "assets/**",
    "language-configuration.json",
    "syntaxes/**",
    "out/**",
    "src/**"
]

existing = []
for item in required:
    if item.endswith("/**"):
        folder = ext / item[:-3]
        if folder.exists():
            existing.append(item)
    else:
        if (ext / item).exists():
            existing.append(item)

# Always require marketplace root docs.
for item in ["package.json", "README.md", "CHANGELOG.md", "LICENSE", "assets/**"]:
    if item not in existing:
        existing.append(item)

pkg["files"] = existing

pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ files allowlist:", existing)
PY

echo "[4/10] Ensuring docs/icon exist..."
mkdir -p "$EXT/assets"

[ -f "$EXT/README.md" ] || cat > "$EXT/README.md" <<'EOF'
# PantherLang

Official PantherLang language support, developer tooling, and debug adapter integration for Visual Studio Code.
EOF

[ -f "$EXT/CHANGELOG.md" ] || cat > "$EXT/CHANGELOG.md" <<'EOF'
# Changelog

## 1.0.0

- PantherLang v1.0.0 product alignment.
EOF

cat > "$EXT/LICENSE" <<'EOF'
Copyright (c) Feras Khatib.

All rights reserved unless a separate license is provided by the project owner.
EOF

python3 <<'PY'
from pathlib import Path
if not Path("vscode-extension/assets/pantherlang-icon.png").exists():
    from PIL import Image, ImageDraw, ImageFont
    icon = Path("vscode-extension/assets/pantherlang-icon.png")
    img = Image.new("RGBA", (256, 256), (6, 18, 36, 255))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((16, 16, 240, 240), radius=42, fill=(8, 31, 58, 255), outline=(60, 135, 220, 255), width=5)
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 112)
        small = ImageFont.truetype("DejaVuSans-Bold.ttf", 28)
    except Exception:
        font = small = None
    bbox = draw.textbbox((0,0), "P", font=font)
    draw.text(((256-(bbox[2]-bbox[0]))/2, 62), "P", font=font, fill=(235, 245, 255, 255))
    draw.text((57, 184), "LANG", font=small, fill=(100, 170, 255, 255))
    img.save(icon)
print("✅ docs/icon ready")
PY

echo "[5/10] Cleaning .vscodeignore conflicts..."
if [ -f "$EXT/.vscodeignore" ]; then
  cp "$EXT/.vscodeignore" "$BACKUP/.vscodeignore.before"
  sed -i \
    -e '/^README\.md$/d' \
    -e '/^CHANGELOG\.md$/d' \
    -e '/^LICENSE$/d' \
    -e '/^assets$/d' \
    -e '/^assets\//d' \
    -e '/^assets\/\*\*/d' \
    "$EXT/.vscodeignore"
fi

echo "[6/10] Pre-package validation..."
node <<'NODE'
const fs = require("fs");
const path = require("path");
const pkg = JSON.parse(fs.readFileSync("vscode-extension/package.json", "utf8"));
function assert(c,m){ if(!c) throw new Error(m); }
assert(pkg.version === "1.0.0", "version mismatch");
assert(pkg.icon === "assets/pantherlang-icon.png", "bad icon");
assert(fs.existsSync(path.join("vscode-extension", pkg.icon)), "icon missing");
assert(fs.existsSync("vscode-extension/README.md"), "README missing");
assert(fs.existsSync("vscode-extension/CHANGELOG.md"), "CHANGELOG missing");
assert(fs.existsSync("vscode-extension/LICENSE"), "LICENSE missing");
for (const pattern of pkg.files || []) {
  if (pattern.endsWith("/**")) {
    const folder = pattern.slice(0,-3);
    if (!fs.existsSync(path.join("vscode-extension", folder))) throw new Error("unused files pattern: "+pattern);
  } else {
    if (!fs.existsSync(path.join("vscode-extension", pattern))) throw new Error("unused files pattern: "+pattern);
  }
}
console.log("✅ pre-package OK");
NODE

echo "[7/10] Rebuilding VSIX..."
rm -f "$EXT"/*.vsix
(
  cd "$EXT"
  npx --yes @vscode/vsce package --no-dependencies
)

echo "[8/10] Copying and inspecting VSIX..."
VSIX="$(ls -t "$EXT"/*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX not created"

cp "$VSIX" "$VSIX_DIR/$(basename "$VSIX")"
sha256sum "$VSIX_DIR/$(basename "$VSIX")" > "$VSIX_DIR/$(basename "$VSIX").sha256"

python3 <<PY
from pathlib import Path
import zipfile, json
vsix = Path("$VSIX_DIR/$(basename "$VSIX")")
with zipfile.ZipFile(vsix) as z:
    names = set(z.namelist())
    required = [
        "extension/package.json",
        "extension/assets/pantherlang-icon.png",
        "extension/README.md",
        "extension/CHANGELOG.md",
        "extension/LICENSE",
    ]
    missing = [x for x in required if x not in names]
    if missing:
        raise SystemExit(f"Missing from VSIX: {missing}")
    pkg = json.loads(z.read("extension/package.json").decode("utf-8"))
    assert pkg["version"] == "1.0.0"
    assert pkg["icon"] == "assets/pantherlang-icon.png"
print("✅ VSIX contents verified")
PY

echo "[9/10] Regression verification..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

cat > "$REPORTS/R1_PART7_V3_VSCE_FILES_ALLOWLIST_FIX.md" <<EOF
# R1 Part 7 v3 - VSCE Files Allowlist Fix

## Status

PASSED

## Fixed

- Removed unused files patterns from package.json
- Included README, CHANGELOG, LICENSE, and icon in VSIX
- Rebuilt PantherLang 1.0.0 VSIX successfully

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Next

R1 Final Integration.
EOF

cat > "$R1/status_part7_release_verification.json" <<EOF
{
  "ok": true,
  "phase": "R1",
  "part": "7",
  "status": "PASSED",
  "name": "Release Verification",
  "version": "1.0.0",
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "runtime_modified": true,
  "next": "R1 Final Integration"
}
EOF

echo "[10/10] Done."
echo "============================================================"
echo "✅ R1 Part 7 COMPLETE"
echo "✅ VSIX DOCUMENTATION VERIFIED"
echo "Next: R1 Final Integration"
echo "============================================================"
