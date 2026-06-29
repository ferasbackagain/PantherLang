#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R2"
echo " Marketplace Professionalization / Publish Gate"
echo " Part 4 - Marketplace Publish Dry Run"
echo "============================================================"

ROOT="$(pwd)"
R2="$ROOT/.panther/R2_marketplace_professionalization"
REPORTS="$ROOT/reports/R2_marketplace"
EXT="$ROOT/vscode-extension"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R2" "$REPORTS"

fail(){ echo "[R2-P4][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight gates..."
[ -f "$R2/status_part3_local_install_runtime_smoke.json" ] || fail "Run R2 Part 3 first."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "package.json missing."

echo "[2/10] Resolving VSIX..."
VSIX="$(python3 - <<'PY'
import json
from pathlib import Path
status=Path(".panther/R2_marketplace_professionalization/status_part3_local_install_runtime_smoke.json")
data=json.loads(status.read_text())
p=Path(data.get("vsix",""))
if p.exists():
    print(p)
else:
    xs=sorted(Path("releases/vscode_marketplace").glob("pantherlang-1.0.0*.vsix"), key=lambda x:x.stat().st_mtime, reverse=True)
    print(xs[0] if xs else "")
PY
)"
[ -f "$VSIX" ] || fail "VSIX not found."
echo "VSIX: $VSIX"

echo "[3/10] Regression gates..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

echo "[4/10] VSIX checksum/content gate..."
[ -f "$VSIX.sha256" ] || sha256sum "$VSIX" > "$VSIX.sha256"
sha256sum -c "$VSIX.sha256"

python3 <<PY
from pathlib import Path
import zipfile,json
vsix=Path("$VSIX")
with zipfile.ZipFile(vsix) as z:
    names=set(z.namelist())
    lower={n.lower():n for n in names}
    assert "extension/package.json" in names
    assert "extension/assets/pantherlang-icon.png" in names
    assert "extension/readme.md" in lower
    assert "extension/changelog.md" in lower
    assert any(x in lower for x in ["extension/license","extension/license.md","extension/license.txt"])
    pkg=json.loads(z.read("extension/package.json").decode())
    assert pkg["publisher"]=="pantherlang"
    assert pkg["name"]=="pantherlang"
    assert pkg["version"]=="1.0.0"
print("✅ VSIX publish artifact verified")
PY

echo "[5/10] VSCE package/dry-run validation..."
(
  cd "$EXT"
  npx --yes @vscode/vsce ls --tree > "$R2/part4_vsce_ls_tree_${STAMP}.txt"
)

grep -qi "pantherlang-icon.png" "$R2/part4_vsce_ls_tree_${STAMP}.txt" || fail "Icon missing from vsce ls"
grep -qi "readme.md" "$R2/part4_vsce_ls_tree_${STAMP}.txt" || fail "README missing from vsce ls"
grep -qi "changelog.md" "$R2/part4_vsce_ls_tree_${STAMP}.txt" || fail "CHANGELOG missing from vsce ls"
grep -qi "license" "$R2/part4_vsce_ls_tree_${STAMP}.txt" || fail "LICENSE missing from vsce ls"

echo "[6/10] Creating dry-run publish commands..."
cat > "$R2/PUBLISH_DRY_RUN_RESULT.md" <<EOF
# PantherLang Marketplace Publish Dry Run

## Status

PASSED

## Artifact

\`$VSIX\`

## Publisher

\`pantherlang\`

## Extension ID expected

\`pantherlang.pantherlang\`

## Dry-run result

VSIX package exists, checksums validate, metadata validates, and VSCE package tree contains required Marketplace files.

## Manual pre-publish check

\`\`\`bash
cd vscode-extension
npx --yes @vscode/vsce ls --tree
\`\`\`

## Publish command with token

\`\`\`bash
cd vscode-extension
VSCE_PAT=<your_marketplace_token> npx --yes @vscode/vsce publish --packagePath ../$VSIX
\`\`\`

## Safer publish gate script

\`\`\`bash
VSCE_PAT=<your_marketplace_token> bash .panther/R2_marketplace_professionalization/publish_from_vsix_gate.sh
\`\`\`
EOF

cat > "$R2/publish_from_vsix_gate.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ROOT="\$(git rev-parse --show-toplevel)"
cd "\$ROOT/vscode-extension"

[ -n "\${VSCE_PAT:-}" ] || {
  echo "[PUBLISH][ERROR] VSCE_PAT missing."
  echo "Usage:"
  echo "  VSCE_PAT=<token> bash .panther/R2_marketplace_professionalization/publish_from_vsix_gate.sh"
  exit 1
}

npx --yes @vscode/vsce publish --packagePath "../$VSIX"
EOF
chmod +x "$R2/publish_from_vsix_gate.sh"

echo "[7/10] Checking token presence without publishing..."
if [ -n "${VSCE_PAT:-}" ]; then
  TOKEN_PRESENT=true
  echo "✅ VSCE_PAT is present, but dry run will NOT publish."
else
  TOKEN_PRESENT=false
  echo "VSCE_PAT not present. Publish remains gated."
fi

echo "[8/10] Creating dry-run manifest..."
python3 <<PY
from pathlib import Path
import hashlib,json
from datetime import datetime,timezone

root=Path.cwd()
r2=root/".panther/R2_marketplace_professionalization"
vsix=Path("$VSIX")
manifest={
    "ok": True,
    "phase": "R2",
    "part": "4",
    "name": "Marketplace Publish Dry Run",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": False,
    "version": "1.0.0",
    "publisher": "pantherlang",
    "expected_extension_id": "pantherlang.pantherlang",
    "vsix": vsix.as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "token_present": "$TOKEN_PRESENT",
    "published": False,
    "dry_run_result": "PASSED",
    "publish_gate_script": ".panther/R2_marketplace_professionalization/publish_from_vsix_gate.sh",
    "next": "R2 Part 5 - Final Publish Gate / Marketplace Release"
}
(r2/"part4_marketplace_publish_dry_run_manifest.json").write_text(json.dumps(manifest,indent=2,sort_keys=True),encoding="utf-8")
print("✅ dry-run manifest written")
PY

echo "[9/10] Writing engineering report..."
cat > "$REPORTS/R2_PART4_MARKETPLACE_PUBLISH_DRY_RUN.md" <<EOF
# R2 Part 4 - Marketplace Publish Dry Run

## Status

PASSED

## Verified

- Regression gates
- VSIX checksum
- VSIX content
- Publisher/name/version
- VSCE package tree
- Publish commands generated
- Publish gate script generated

## No publish performed

This part intentionally does not publish to Marketplace.

## Next

R2 Part 5 - Final Publish Gate / Marketplace Release.
EOF

echo "[10/10] Writing status..."
cat > "$R2/status_part4_marketplace_publish_dry_run.json" <<EOF
{
  "ok": true,
  "phase": "R2",
  "part": "4",
  "status": "PASSED",
  "name": "Marketplace Publish Dry Run",
  "runtime_modified": false,
  "published": false,
  "vsix": "$VSIX",
  "next": "R2 Part 5 - Final Publish Gate / Marketplace Release"
}
EOF

echo "============================================================"
echo "✅ R2 Part 4 COMPLETE"
echo "✅ Marketplace Publish Dry Run PASSED"
echo "Next: R2 Part 5 - Final Publish Gate / Marketplace Release"
echo "============================================================"
