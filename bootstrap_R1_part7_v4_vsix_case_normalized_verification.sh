#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R1"
echo " Product Unification"
echo " Part 7 v4 - VSIX Case-Normalized Verification Fix"
echo "============================================================"

ROOT="$(pwd)"
R1="$ROOT/.panther/R1_product_unification"
REPORTS="$ROOT/reports/R1_product_unification"
EXT="$ROOT/vscode-extension"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
BACKUP="$ROOT/.panther/backups/R1_part7_v4_vsix_case_normalized_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R1" "$REPORTS" "$BACKUP" "$VSIX_DIR"

fail(){ echo "[R1-P7-v4][ERROR] $1" >&2; exit 1; }

echo "[1/9] Pre-flight gates..."
[ -f "$R1/status_part6_vscode_extension_alignment.json" ] || fail "Run R1 Part 6 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."

echo "[2/9] Safety backup..."
cp -a "$EXT" "$BACKUP/vscode-extension"

echo "[3/9] Ensuring Marketplace files and clean allowlist..."
python3 <<'PY'
from pathlib import Path
import json

ext = Path("vscode-extension")
pkg_path = ext / "package.json"
pkg = json.loads(pkg_path.read_text())

pkg["version"] = "1.0.0"
pkg["icon"] = "assets/pantherlang-icon.png"
pkg["galleryBanner"] = {"color": "#0B1F3A", "theme": "dark"}

# Keep only existing include patterns. VSCE lowercases some root docs inside package;
# that is normal and will be accepted by the verifier.
candidate_files = [
    "package.json",
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "assets/**",
    "language-configuration.json",
    "syntaxes/**",
    "out/**",
    "src/**",
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
print("✅ package.json normalized")
PY

echo "[4/9] Cleaning .vscodeignore conflicts..."
if [ -f "$EXT/.vscodeignore" ]; then
  cp "$EXT/.vscodeignore" "$BACKUP/.vscodeignore.before"
  sed -i \
    -e '/^README\.md$/Id' \
    -e '/^CHANGELOG\.md$/Id' \
    -e '/^LICENSE$/Id' \
    -e '/^LICENSE\.txt$/Id' \
    -e '/^assets$/Id' \
    -e '/^assets\//Id' \
    -e '/^assets\/\*\*/Id' \
    "$EXT/.vscodeignore"
fi

echo "[5/9] Pre-package validation..."
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
console.log("✅ pre-package OK");
NODE

echo "[6/9] Rebuilding VSIX..."
rm -f "$EXT"/*.vsix
(
  cd "$EXT"
  npx --yes @vscode/vsce package --no-dependencies
)

echo "[7/9] Copying and case-normalized VSIX inspection..."
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
    lower = {name.lower(): name for name in names}

    required_exact = [
        "extension/package.json",
        "extension/assets/pantherlang-icon.png",
    ]
    missing_exact = [x for x in required_exact if x not in names]
    if missing_exact:
        raise SystemExit(f"Missing exact VSIX paths: {missing_exact}")

    # VSCE normalizes some root docs:
    # README.md -> readme.md
    # CHANGELOG.md -> changelog.md
    # LICENSE -> LICENSE.txt
    required_case_insensitive = [
        "extension/readme.md",
        "extension/changelog.md",
    ]
    missing_ci = [x for x in required_case_insensitive if x not in lower]
    if missing_ci:
        raise SystemExit(f"Missing normalized VSIX docs: {missing_ci}")

    license_ok = any(x in lower for x in [
        "extension/license",
        "extension/license.md",
        "extension/license.txt",
    ])
    if not license_ok:
        raise SystemExit("Missing normalized VSIX license file")

    pkg = json.loads(z.read("extension/package.json").decode("utf-8"))
    assert pkg["version"] == "1.0.0"
    assert pkg["icon"] == "assets/pantherlang-icon.png"
    assert pkg["galleryBanner"]["color"] == "#0B1F3A"

print("✅ VSIX normalized docs/assets verified")
PY

echo "[8/9] Regression verification..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

cat > "$REPORTS/R1_PART7_V4_VSIX_CASE_NORMALIZED_VERIFICATION.md" <<EOF
# R1 Part 7 v4 - VSIX Case-Normalized Verification Fix

## Status

PASSED

## Fixed

- Accepted VSCE-normalized root documentation paths:
  - \`README.md\` packaged as \`readme.md\`
  - \`CHANGELOG.md\` packaged as \`changelog.md\`
  - \`LICENSE\` packaged as \`LICENSE.txt\`
- Verified icon remains \`extension/assets/pantherlang-icon.png\`
- Verified package version is \`1.0.0\`
- Verified dark-blue gallery banner

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

echo "[9/9] Done."
echo "============================================================"
echo "✅ R1 Part 7 COMPLETE"
echo "✅ VSIX DOCUMENTATION VERIFIED"
echo "Next: R1 Final Integration"
echo "============================================================"
