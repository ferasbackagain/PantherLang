#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R2"
echo " Marketplace Professionalization / Publish Gate"
echo " Part 2 - Publisher Identity + Package Finalization"
echo "============================================================"

ROOT="$(pwd)"
R2="$ROOT/.panther/R2_marketplace_professionalization"
REPORTS="$ROOT/reports/R2_marketplace"
EXT="$ROOT/vscode-extension"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
BACKUP="$ROOT/.panther/backups/R2_part2_publisher_identity_$(date +%Y%m%d_%H%M%S)"
TARGET_VERSION="1.0.0"

# Default publisher is pantherlang; override safely:
#   PANTHER_PUBLISHER=myPublisher bash bootstrap_R2_part2_publisher_identity_package_finalization.sh
PUBLISHER="${PANTHER_PUBLISHER:-pantherlang}"

mkdir -p "$R2" "$REPORTS" "$BACKUP" "$VSIX_DIR"

fail(){ echo "[R2-P2][ERROR] $1" >&2; exit 1; }
warn(){ echo "[R2-P2][WARN] $1" >&2; }

echo "[1/12] Pre-flight gates..."
[ -f "$R2/status_part1_marketplace_readiness_audit.json" ] || fail "Run R2 Part 1 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/12] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"

echo "[3/12] Baseline regressions..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

echo "[4/12] Finalizing package.json publisher identity..."
python3 <<PY
from pathlib import Path
import json

ext = Path("vscode-extension")
pkg_path = ext / "package.json"
pkg = json.loads(pkg_path.read_text())

publisher = "$PUBLISHER"

pkg["version"] = "$TARGET_VERSION"
pkg["publisher"] = publisher
pkg["name"] = pkg.get("name") or "pantherlang"
pkg["displayName"] = "PantherLang"
pkg["description"] = "Official PantherLang language support, developer tooling, and debug adapter integration for Visual Studio Code."
pkg["icon"] = "assets/pantherlang-icon.png"
pkg["galleryBanner"] = {"color": "#0B1F3A", "theme": "dark"}

pkg["repository"] = pkg.get("repository") or {
    "type": "git",
    "url": "https://github.com/feras-khatib/pantherlang.git"
}
pkg["bugs"] = pkg.get("bugs") or {
    "url": "https://github.com/feras-khatib/pantherlang/issues"
}
pkg["homepage"] = pkg.get("homepage") or "https://github.com/feras-khatib/pantherlang"

keywords = set(pkg.get("keywords") or [])
keywords.update(["pantherlang", "panther", "compiler", "debugger", "language-server", "vscode-extension", "developer-tools"])
pkg["keywords"] = sorted(keywords)

categories = set(pkg.get("categories") or [])
categories.update(["Programming Languages", "Debuggers", "Other"])
pkg["categories"] = sorted(categories)

pkg.setdefault("engines", {})["vscode"] = pkg.get("engines", {}).get("vscode") or "^1.85.0"

# Keep only existing package files to avoid VSCE unused-pattern failure.
candidate_files = [
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
files = []
for item in candidate_files:
    if item.endswith("/**"):
        if (ext / item[:-3]).exists():
            files.append(item)
    else:
        if (ext / item).exists():
            files.append(item)
for required in ["package.json", "README.md", "CHANGELOG.md", "LICENSE", "assets/**"]:
    if required not in files:
        files.append(required)
pkg["files"] = files

pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ publisher:", publisher)
print("✅ version:", pkg["version"])
PY

echo "[5/12] Ensuring Marketplace docs and icon..."
mkdir -p "$EXT/assets"

cat > "$EXT/README.md" <<'EOF'
# PantherLang

Official PantherLang language support, developer tooling, and debug adapter integration for Visual Studio Code.

## Features

- PantherLang syntax support for `.pan` and `.panther`
- PantherLang project workflow support
- PantherLang run/debug command integration
- Official PantherLang Debug Adapter support
- Dark-blue PantherLang Marketplace identity

## Requirements

Install PantherLang CLI and ensure it is available on your PATH.

## Getting Started

1. Install the extension.
2. Open a `.pan` or `.panther` file.
3. Run `PantherLang: Doctor`.
4. Create a PantherLang project.
5. Run or debug your program.

## Release

PantherLang Developer Edition v1.0.0.
EOF

cat > "$EXT/CHANGELOG.md" <<'EOF'
# Changelog

## 1.0.0

- Unified PantherLang product version.
- Official Debug Adapter release integrated.
- VS Code Marketplace readiness completed.
- Dark-blue PantherLang branding.
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
print("✅ icon ready")
PY

echo "[6/12] Package metadata validation..."
node <<'NODE'
const fs = require("fs");
const path = require("path");
const pkg = JSON.parse(fs.readFileSync("vscode-extension/package.json", "utf8"));
function assert(c,m){ if(!c) throw new Error(m); }
assert(pkg.publisher && pkg.publisher.length > 0, "publisher missing");
assert(pkg.version === "1.0.0", "version mismatch");
assert(pkg.icon === "assets/pantherlang-icon.png", "bad icon");
assert(fs.existsSync(path.join("vscode-extension", pkg.icon)), "icon missing");
assert(fs.existsSync("vscode-extension/README.md"), "README missing");
assert(fs.existsSync("vscode-extension/CHANGELOG.md"), "CHANGELOG missing");
assert(fs.existsSync("vscode-extension/LICENSE"), "LICENSE missing");
assert(pkg.galleryBanner.color === "#0B1F3A", "dark-blue gallery banner missing");
console.log("✅ package metadata valid");
NODE

echo "[7/12] VSCE list audit..."
(
  cd "$EXT"
  npx --yes @vscode/vsce ls --tree > "$R2/part2_vsce_ls_tree.txt"
)
grep -qi "pantherlang-icon.png" "$R2/part2_vsce_ls_tree.txt" || fail "Icon missing from vsce ls tree"
grep -qi "readme.md" "$R2/part2_vsce_ls_tree.txt" || fail "README missing from vsce ls tree"
grep -qi "changelog.md" "$R2/part2_vsce_ls_tree.txt" || fail "CHANGELOG missing from vsce ls tree"
grep -qi "LICENSE" "$R2/part2_vsce_ls_tree.txt" || fail "LICENSE missing from vsce ls tree"

echo "[8/12] Rebuilding final publisher-identity VSIX..."
rm -f "$EXT"/*.vsix
(
  cd "$EXT"
  npx --yes @vscode/vsce package --no-dependencies
)

VSIX="$(ls -t "$EXT"/*.vsix | head -1)"
[ -f "$VSIX" ] || fail "VSIX not created"

cp "$VSIX" "$VSIX_DIR/$(basename "$VSIX")"
sha256sum "$VSIX_DIR/$(basename "$VSIX")" > "$VSIX_DIR/$(basename "$VSIX").sha256"

echo "[9/12] VSIX content verification..."
python3 <<PY
from pathlib import Path
import zipfile, json
vsix = Path("$VSIX_DIR/$(basename "$VSIX")")
with zipfile.ZipFile(vsix) as z:
    names = set(z.namelist())
    lower = {n.lower(): n for n in names}
    assert "extension/package.json" in names
    assert "extension/assets/pantherlang-icon.png" in names
    assert "extension/readme.md" in lower
    assert "extension/changelog.md" in lower
    assert any(x in lower for x in ["extension/license", "extension/license.md", "extension/license.txt"])
    pkg = json.loads(z.read("extension/package.json").decode("utf-8"))
    assert pkg["version"] == "1.0.0"
    assert pkg["publisher"] == "$PUBLISHER"
    assert pkg["icon"] == "assets/pantherlang-icon.png"
print("✅ VSIX content verified")
PY

echo "[10/12] Creating publish gate commands..."
cat > "$R2/PUBLISH_COMMANDS.md" <<EOF
# PantherLang VS Code Marketplace Publish Commands

## Publisher

\`$PUBLISHER\`

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Local install test

\`\`\`bash
code --install-extension releases/vscode_marketplace/$(basename "$VSIX")
\`\`\`

## Interactive Marketplace login

\`\`\`bash
cd vscode-extension
npx --yes @vscode/vsce login $PUBLISHER
npx --yes @vscode/vsce publish
\`\`\`

## Non-interactive token publish

\`\`\`bash
cd vscode-extension
VSCE_PAT=<your_marketplace_token> npx --yes @vscode/vsce publish
\`\`\`

## Safer publish from VSIX

\`\`\`bash
cd vscode-extension
VSCE_PAT=<your_marketplace_token> npx --yes @vscode/vsce publish --packagePath ../releases/vscode_marketplace/$(basename "$VSIX")
\`\`\`
EOF

cat > "$R2/publish_from_vsix_gate.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "\$(git rev-parse --show-toplevel)/vscode-extension"
[ -n "\${VSCE_PAT:-}" ] || { echo "[PUBLISH][ERROR] VSCE_PAT missing"; exit 1; }
npx --yes @vscode/vsce publish --packagePath "../releases/vscode_marketplace/$(basename "$VSIX")"
EOF
chmod +x "$R2/publish_from_vsix_gate.sh"

echo "[11/12] Writing manifest/report..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone
root = Path.cwd()
r2 = root / ".panther/R2_marketplace_professionalization"
vsix = root / "releases/vscode_marketplace/$(basename "$VSIX")"
manifest = {
    "ok": True,
    "phase": "R2",
    "part": "2",
    "name": "Publisher Identity + Package Finalization",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.0",
    "publisher": "$PUBLISHER",
    "runtime_modified": True,
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "publish_commands": ".panther/R2_marketplace_professionalization/PUBLISH_COMMANDS.md",
    "publish_gate": ".panther/R2_marketplace_professionalization/publish_from_vsix_gate.sh",
    "next": "R2 Part 3 - Local Install + Runtime Smoke Test"
}
(r2 / "part2_publisher_identity_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ manifest written")
PY

cat > "$REPORTS/R2_PART2_PUBLISHER_IDENTITY_PACKAGE_FINALIZATION.md" <<EOF
# R2 Part 2 - Publisher Identity + Package Finalization

## Status

PASSED

## Publisher

\`$PUBLISHER\`

## VSIX

\`releases/vscode_marketplace/$(basename "$VSIX")\`

## Verified

- package.json publisher identity
- version 1.0.0
- dark-blue gallery banner
- icon packaged
- README/CHANGELOG/LICENSE packaged
- VSCE tree audit
- VSIX content audit

## Next

R2 Part 3 - Local Install + Runtime Smoke Test.
EOF

echo "[12/12] Writing status..."
cat > "$R2/status_part2_publisher_identity_package_finalization.json" <<EOF
{
  "ok": true,
  "phase": "R2",
  "part": "2",
  "status": "PASSED",
  "name": "Publisher Identity + Package Finalization",
  "publisher": "$PUBLISHER",
  "version": "1.0.0",
  "runtime_modified": true,
  "vsix": "releases/vscode_marketplace/$(basename "$VSIX")",
  "next": "R2 Part 3 - Local Install + Runtime Smoke Test"
}
EOF

echo "============================================================"
echo "✅ R2 Part 2 COMPLETE"
echo "Publisher: $PUBLISHER"
echo "VSIX: releases/vscode_marketplace/$(basename "$VSIX")"
echo "Next: R2 Part 3 - Local Install + Runtime Smoke Test"
echo "============================================================"
