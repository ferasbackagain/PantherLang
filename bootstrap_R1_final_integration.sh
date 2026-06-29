#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R1"
echo " Product Unification"
echo " Final Integration"
echo "============================================================"

ROOT="$(pwd)"
R1="$ROOT/.panther/R1_product_unification"
REPORTS="$ROOT/reports/R1_product_unification"
RELEASES="$ROOT/releases/R1_product_unification"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
STAMP="$(date +%Y%m%d_%H%M%S)"
TARGET_VERSION="1.0.0"

mkdir -p "$R1" "$REPORTS" "$RELEASES"

fail(){ echo "[R1-FINAL][ERROR] $1" >&2; exit 1; }

echo "[1/12] Checking R1 gates..."
for f in \
  "$R1/status_part1_product_inventory.json" \
  "$R1/status_part2_unified_version_contract.json" \
  "$R1/status_part3_repository_synchronization.json" \
  "$R1/status_part4_cli_runtime_version_alignment.json" \
  "$R1/status_part5_compiler_toolchain_alignment.json" \
  "$R1/status_part6_vscode_extension_alignment.json" \
  "$R1/status_part7_release_verification.json"
do
  [ -f "$f" ] || fail "Missing R1 gate: $f"
done

echo "[2/12] Resolving VSIX..."
VSIX="$(python3 - <<'PY'
import json
from pathlib import Path
status = Path(".panther/R1_product_unification/status_part7_release_verification.json")
data = json.loads(status.read_text())
candidate = Path(data.get("vsix", ""))
if candidate.exists():
    print(candidate)
else:
    matches = sorted(Path("releases/vscode_marketplace").glob("pantherlang-1.0.0*.vsix"), key=lambda p: p.stat().st_mtime, reverse=True)
    print(matches[0] if matches else "")
PY
)"
[ -f "$VSIX" ] || fail "VSIX missing."
echo "VSIX: $VSIX"

echo "[3/12] Production compile + regressions..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

echo "[4/12] VS Code extension metadata verification..."
node <<'NODE'
const fs = require("fs");
const path = require("path");
const pkg = JSON.parse(fs.readFileSync("vscode-extension/package.json", "utf8"));
function assert(c,m){ if(!c) throw new Error(m); }
assert(pkg.version === "1.0.0", "version must be 1.0.0");
assert(pkg.icon === "assets/pantherlang-icon.png", "icon path mismatch");
assert(pkg.galleryBanner && pkg.galleryBanner.color === "#0B1F3A", "dark-blue banner missing");
assert(fs.existsSync(path.join("vscode-extension", pkg.icon)), "icon file missing");
assert(fs.existsSync("vscode-extension/README.md"), "README missing");
assert(fs.existsSync("vscode-extension/CHANGELOG.md"), "CHANGELOG missing");
assert(fs.existsSync("vscode-extension/LICENSE"), "LICENSE missing");
console.log("✅ package.json metadata OK");
NODE

echo "[5/12] VSIX checksum + content verification..."
[ -f "$VSIX.sha256" ] || sha256sum "$VSIX" > "$VSIX.sha256"
sha256sum -c "$VSIX.sha256"

python3 <<PY
from pathlib import Path
import zipfile, json
vsix = Path("$VSIX")
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
    assert pkg["icon"] == "assets/pantherlang-icon.png"
    assert pkg["galleryBanner"]["color"] == "#0B1F3A"
print("✅ VSIX content OK")
PY

echo "[6/12] Creating R1 final manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r1 = root / ".panther" / "R1_product_unification"
vsix = Path("$VSIX")

def hash_tree(base: Path):
    rows = []
    if not base.exists():
        return rows
    for p in sorted(base.rglob("*")):
        if p.is_file() and ".git" not in p.parts and "__pycache__" not in p.parts:
            rows.append({
                "path": p.relative_to(root).as_posix(),
                "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
                "size": p.stat().st_size,
            })
    return rows

statuses = {}
for p in sorted(r1.glob("status_*.json")):
    try:
        statuses[p.name] = json.loads(p.read_text())
    except Exception:
        statuses[p.name] = {"parse_error": True}

manifest = {
    "ok": True,
    "phase": "R1",
    "status": "COMPLETE",
    "name": "PantherLang Product Unification",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "target_version": "1.0.0",
    "release_name": "PantherLang Developer Edition v1.0.0",
    "runtime_modified": True,
    "completed_parts": [
        "Part 1 - Official Product Inventory",
        "Part 2 - Unified Version Contract",
        "Part 3 - Repository Synchronization",
        "Part 4 - CLI + Runtime Version Alignment",
        "Part 5 - Compiler + Toolchain Alignment",
        "Part 6 - VS Code Extension Alignment",
        "Part 7 - Release Verification"
    ],
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "statuses": statuses,
    "aligned_files": hash_tree(root / "panther_core") + hash_tree(root / "cli") + hash_tree(root / "runtime") + hash_tree(root / "compiler") + hash_tree(root / "toolchain"),
    "vscode_extension_files": hash_tree(root / "vscode-extension"),
    "next": "R2 - Marketplace Professionalization / Publish Gate"
}
(r1 / "R1_FINAL_INTEGRATION_MANIFEST.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ final manifest generated")
PY

echo "[7/12] Creating official R1 release notes..."
cat > "$REPORTS/R1_FINAL_INTEGRATION_REPORT.md" <<EOF
# PantherLang R1 - Final Integration

## Status

COMPLETE

## Release

PantherLang Developer Edition v1.0.0

## Completed

- Official Product Inventory
- Unified Version Contract
- Repository Synchronization
- CLI + Runtime Version Alignment
- Compiler + Toolchain Alignment
- VS Code Extension Alignment
- Release Verification

## VS Code Extension

VSIX:

\`$VSIX\`

Local install:

\`\`\`bash
code --install-extension $VSIX
\`\`\`

## Branding

- Primary identity: dark blue
- Gallery banner: \`#0B1F3A\`
- Icon: \`assets/pantherlang-icon.png\`

## Next

R2 - Marketplace Professionalization / Publish Gate.
EOF

echo "[8/12] Creating R1 archive..."
ARCHIVE="$RELEASES/PantherLang_R1_Product_Unification_v${TARGET_VERSION}_${STAMP}.tar.gz"
tar -czf "$ARCHIVE" \
  .panther/R1_product_unification \
  reports/R1_product_unification \
  panther_core \
  cli/version.py \
  runtime/version.py \
  compiler/version.py \
  toolchain/version.py \
  vscode-extension/package.json \
  vscode-extension/README.md \
  vscode-extension/CHANGELOG.md \
  vscode-extension/LICENSE \
  vscode-extension/assets \
  "$VSIX"

sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

echo "[9/12] Git safety status snapshot..."
git status --short > "$R1/git_status_after_R1_final_${STAMP}.txt" || true

echo "[10/12] Writing R1 completion marker..."
cat > "$R1/R1_COMPLETE.txt" <<EOF
PantherLang R1 Product Unification COMPLETE
Version: 1.0.0
VSIX: $VSIX
Archive: $ARCHIVE
Next: R2 Marketplace Professionalization / Publish Gate
EOF

echo "[11/12] Writing final status..."
cat > "$R1/status_R1_final_integration.json" <<EOF
{
  "ok": true,
  "phase": "R1",
  "status": "COMPLETE",
  "name": "Product Unification Final Integration",
  "target_version": "1.0.0",
  "release_name": "PantherLang Developer Edition v1.0.0",
  "vsix": "$VSIX",
  "archive": "$ARCHIVE",
  "runtime_modified": true,
  "next": "R2 - Marketplace Professionalization / Publish Gate"
}
EOF

echo "[12/12] Summary..."
echo "VSIX: $VSIX"
echo "Archive: $ARCHIVE"
ls -lh "$VSIX" "$ARCHIVE"

echo "============================================================"
echo "✅ R1 FINAL INTEGRATION COMPLETE"
echo "✅ PantherLang Developer Edition v1.0.0 UNIFIED"
echo "Next: R2 - Marketplace Professionalization / Publish Gate"
echo "============================================================"
