#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R1"
echo " Product Unification"
echo " Part 7 v2 - VSIX Documentation Inclusion Fix"
echo "============================================================"

ROOT="$(pwd)"
R1="$ROOT/.panther/R1_product_unification"
REPORTS="$ROOT/reports/R1_product_unification"
EXT="$ROOT/vscode-extension"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
BACKUP="$ROOT/.panther/backups/R1_part7_v2_vsix_docs_fix_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R1" "$REPORTS" "$BACKUP"

fail(){ echo "[R1-P7-v2][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight gates..."
[ -f "$R1/status_part6_vscode_extension_alignment.json" ] || fail "Run R1 Part 6 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/10] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"

echo "[3/10] Ensuring Marketplace docs exist..."
cat > "$EXT/README.md" <<'EOF'
# PantherLang

Official PantherLang language support, developer tooling, and debug adapter integration for Visual Studio Code.

## Features

- PantherLang syntax support for `.pan` and `.panther`
- PantherLang project workflow
- PantherLang command integration
- Official PantherLang Debug Adapter support
- Dark-blue PantherLang marketplace identity

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
- Official PantherLang Debug Adapter release.
- VS Code Marketplace package prepared.
- Dark-blue PantherLang identity applied.
EOF

cat > "$EXT/LICENSE" <<'EOF'
Copyright (c) Feras Khatib.

All rights reserved unless a separate license is provided by the project owner.
EOF

echo "[4/10] Hard-fixing package.json files allowlist..."
python3 <<'PY'
from pathlib import Path
import json

pkg_path = Path("vscode-extension/package.json")
pkg = json.loads(pkg_path.read_text())

pkg["version"] = "1.0.0"
pkg["icon"] = "assets/pantherlang-icon.png"
pkg["galleryBanner"] = {"color": "#0B1F3A", "theme": "dark"}

# VSCE only includes files in "files" if this allowlist exists.
# Ensure docs/assets are explicitly included.
files = pkg.get("files")
if files is None:
    files = []
elif not isinstance(files, list):
    files = []

required = [
    "package.json",
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "assets/**",
    "syntaxes/**",
    "snippets/**",
    "out/**",
    "src/**",
    "language-configuration.json",
    "*.json",
    "*.js",
    "*.ts"
]
for item in required:
    if item not in files:
        files.append(item)

pkg["files"] = files
pkg_path.write_text(json.dumps(pkg, indent=2, ensure_ascii=False) + "\n")
print("✅ package.json files allowlist fixed")
PY

echo "[5/10] Fixing .vscodeignore so docs are not excluded..."
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

echo "[6/10] Validating extension metadata before package..."
node <<'NODE'
const fs = require("fs");
const path = require("path");
const pkg = JSON.parse(fs.readFileSync("vscode-extension/package.json", "utf8"));

function assert(cond, msg){ if(!cond) throw new Error(msg); }

assert(pkg.version === "1.0.0", "version must be 1.0.0");
assert(pkg.icon === "assets/pantherlang-icon.png", "bad icon path");
assert(fs.existsSync(path.join("vscode-extension", pkg.icon)), "icon missing");
assert(fs.existsSync("vscode-extension/README.md"), "README missing");
assert(fs.existsSync("vscode-extension/CHANGELOG.md"), "CHANGELOG missing");
assert(fs.existsSync("vscode-extension/LICENSE"), "LICENSE missing");
assert(Array.isArray(pkg.files), "package.json files must be array");
assert(pkg.files.includes("README.md"), "files missing README.md");
assert(pkg.files.includes("CHANGELOG.md"), "files missing CHANGELOG.md");
assert(pkg.files.includes("LICENSE"), "files missing LICENSE");
assert(pkg.files.includes("assets/**"), "files missing assets/**");
console.log("✅ pre-package metadata OK");
NODE

echo "[7/10] Rebuilding VSIX..."
rm -f "$EXT"/*.vsix
(
  cd "$EXT"
  npx --yes @vscode/vsce package --no-dependencies
)

echo "[8/10] Copying VSIX and verifying contents..."
mkdir -p "$VSIX_DIR"
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
print("✅ VSIX docs/assets verified")
PY

echo "[9/10] Running full R1 release verification again..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

cat > "$REPORTS/R1_PART7_V2_VSIX_DOCUMENTATION_INCLUSION_FIX.md" <<EOF
# R1 Part 7 v2 - VSIX Documentation Inclusion Fix

## Status

PASSED

## Fixed

- README included in VSIX
- CHANGELOG included in VSIX
- LICENSE included in VSIX
- Icon included in VSIX
- package.json files allowlist updated
- .vscodeignore cleaned for Marketplace-required files

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
