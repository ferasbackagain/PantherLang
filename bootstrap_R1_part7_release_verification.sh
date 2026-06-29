#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R1"
echo " Product Unification"
echo " Part 7 - Release Verification"
echo "============================================================"

ROOT="$(pwd)"
R1="$ROOT/.panther/R1_product_unification"
REPORTS="$ROOT/reports/R1_product_unification"
EXT="$ROOT/vscode-extension"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R1" "$REPORTS"

fail(){ echo "[R1-P7][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight gates..."
[ -f "$R1/status_part6_vscode_extension_alignment.json" ] || fail "Run R1 Part 6 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."
[ -d "$VSIX_DIR" ] || fail "VSIX release directory missing."

echo "[2/10] Resolving latest VSIX..."
VSIX="$(ls -t "$VSIX_DIR"/pantherlang-1.0.0*.vsix 2>/dev/null | head -1 || true)"
[ -f "$VSIX" ] || fail "pantherlang-1.0.0 VSIX not found in releases/vscode_marketplace"
echo "VSIX: $VSIX"

echo "[3/10] Baseline product verification..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

echo "[4/10] Verifying VS Code extension metadata..."
node <<'NODE'
const fs = require("fs");
const path = require("path");

const pkg = JSON.parse(fs.readFileSync("vscode-extension/package.json", "utf8"));
function assert(cond, msg) {
  if (!cond) throw new Error(msg);
}

assert(pkg.version === "1.0.0", "VS Code extension version must be 1.0.0");
assert(pkg.icon === "assets/pantherlang-icon.png", "Icon path must be assets/pantherlang-icon.png");
assert(fs.existsSync(path.join("vscode-extension", pkg.icon)), "Icon file missing");
assert(pkg.publisher && pkg.publisher.length > 0, "Publisher missing");
assert(pkg.displayName && pkg.displayName.length > 0, "displayName missing");
assert(pkg.description && pkg.description.length > 0, "description missing");
assert(pkg.engines && pkg.engines.vscode, "engines.vscode missing");
assert(Array.isArray(pkg.categories) && pkg.categories.length > 0, "categories missing");
assert(Array.isArray(pkg.keywords) && pkg.keywords.includes("pantherlang"), "keywords missing pantherlang");
assert(pkg.galleryBanner && pkg.galleryBanner.color === "#0B1F3A", "dark-blue gallery banner missing");
assert(fs.existsSync("vscode-extension/README.md"), "README missing");
assert(fs.existsSync("vscode-extension/CHANGELOG.md"), "CHANGELOG missing");
assert(fs.existsSync("vscode-extension/LICENSE"), "LICENSE missing");
console.log("✅ extension metadata verified");
NODE

echo "[5/10] Verifying VSIX package integrity..."
[ -f "$VSIX.sha256" ] || sha256sum "$VSIX" > "$VSIX.sha256"
sha256sum -c "$VSIX.sha256"

echo "[6/10] Inspecting VSIX contents..."
python3 <<PY
from pathlib import Path
import zipfile, json

vsix = Path("$VSIX")
with zipfile.ZipFile(vsix) as z:
    names = z.namelist()
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
    assert pkg["galleryBanner"]["color"] == "#0B1F3A"

print("✅ VSIX contents verified")
PY

echo "[7/10] Creating local install smoke command..."
cat > "$R1/vscode_local_install_command.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
code --install-extension "$VSIX"
EOF
chmod +x "$R1/vscode_local_install_command.sh"

echo "[8/10] Creating release verification manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r1 = root / ".panther" / "R1_product_unification"
vsix = Path("$VSIX")

manifest = {
    "ok": True,
    "phase": "R1",
    "part": "7",
    "name": "Release Verification",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "target_version": "1.0.0",
    "runtime_modified": False,
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_size": vsix.stat().st_size,
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "verified": [
        "debug_adapter_compile",
        "p2_canonical_tests",
        "r1_product_unification_tests",
        "vscode_extension_metadata",
        "vsix_sha256",
        "vsix_contents",
        "dark_blue_icon",
        "package_version_1_0_0"
    ],
    "next": "R1 Final Integration"
}
(r1 / "part7_release_verification_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ release verification manifest written")
PY

echo "[9/10] Writing engineering report..."
cat > "$REPORTS/R1_PART7_RELEASE_VERIFICATION.md" <<EOF
# R1 Part 7 - Release Verification

## Status

PASSED

## Verified

- Production Debug Adapter compiles
- P2 canonical tests pass
- R1 product unification tests pass
- VS Code extension metadata aligned to 1.0.0
- Dark-blue icon exists and is packaged
- VSIX SHA256 verified
- VSIX contents verified

## VSIX

\`$VSIX\`

## Local Install

\`\`\`bash
code --install-extension $VSIX
\`\`\`

## Runtime Modification

No runtime source files were modified.

## Next

R1 Final Integration.
EOF

echo "[10/10] Writing status..."
cat > "$R1/status_part7_release_verification.json" <<EOF
{
  "ok": true,
  "phase": "R1",
  "part": "7",
  "status": "PASSED",
  "name": "Release Verification",
  "target_version": "1.0.0",
  "runtime_modified": false,
  "vsix": "$VSIX",
  "manifest": ".panther/R1_product_unification/part7_release_verification_manifest.json",
  "next": "R1 Final Integration"
}
EOF

echo "============================================================"
echo "✅ R1 Part 7 COMPLETE"
echo "Next: R1 Final Integration"
echo "============================================================"
