#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R2"
echo " Marketplace Professionalization / Publish Gate"
echo " Part 1 - Marketplace Readiness Audit"
echo "============================================================"

ROOT="$(pwd)"
R1="$ROOT/.panther/R1_product_unification"
R2="$ROOT/.panther/R2_marketplace_professionalization"
REPORTS="$ROOT/reports/R2_marketplace"
EXT="$ROOT/vscode-extension"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R2" "$REPORTS"

fail(){ echo "[R2-P1][ERROR] $1" >&2; exit 1; }

echo "[1/10] Pre-flight gates..."
[ -f "$R1/status_R1_final_integration.json" ] || fail "R1 final integration missing."
[ -d "$EXT" ] || fail "vscode-extension missing."
[ -f "$EXT/package.json" ] || fail "vscode-extension/package.json missing."
[ -d "$VSIX_DIR" ] || fail "VSIX release directory missing."

echo "[2/10] Resolve VSIX..."
VSIX="$(ls -t "$VSIX_DIR"/pantherlang-1.0.0*.vsix 2>/dev/null | head -1 || true)"
[ -f "$VSIX" ] || fail "pantherlang-1.0.0 VSIX missing."
echo "VSIX: $VSIX"

echo "[3/10] Baseline validation..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

echo "[4/10] Marketplace metadata audit..."
node <<'NODE'
const fs = require("fs");
const path = require("path");
const pkg = JSON.parse(fs.readFileSync("vscode-extension/package.json", "utf8"));

const checks = [];
function check(name, ok, detail="") {
  checks.push({name, ok: !!ok, detail});
}

check("name", !!pkg.name, pkg.name || "");
check("displayName", !!pkg.displayName, pkg.displayName || "");
check("version_1_0_0", pkg.version === "1.0.0", pkg.version || "");
check("publisher", !!pkg.publisher, pkg.publisher || "");
check("description", !!pkg.description && pkg.description.length >= 20, pkg.description || "");
check("engines_vscode", !!(pkg.engines && pkg.engines.vscode), JSON.stringify(pkg.engines || {}));
check("categories", Array.isArray(pkg.categories) && pkg.categories.length > 0, JSON.stringify(pkg.categories || []));
check("keywords", Array.isArray(pkg.keywords) && pkg.keywords.includes("pantherlang"), JSON.stringify(pkg.keywords || []));
check("icon_path", pkg.icon === "assets/pantherlang-icon.png", pkg.icon || "");
check("icon_exists", fs.existsSync(path.join("vscode-extension", pkg.icon || "")), pkg.icon || "");
check("gallery_banner_dark_blue", !!(pkg.galleryBanner && pkg.galleryBanner.color === "#0B1F3A"), JSON.stringify(pkg.galleryBanner || {}));
check("repository", !!pkg.repository, JSON.stringify(pkg.repository || {}));
check("bugs", !!pkg.bugs, JSON.stringify(pkg.bugs || {}));
check("homepage", !!pkg.homepage, pkg.homepage || "");
check("readme", fs.existsSync("vscode-extension/README.md"), "");
check("changelog", fs.existsSync("vscode-extension/CHANGELOG.md"), "");
check("license", fs.existsSync("vscode-extension/LICENSE"), "");
check("contributes", !!pkg.contributes, JSON.stringify(Object.keys(pkg.contributes || {})));

const failed = checks.filter(c => !c.ok);
fs.writeFileSync(".panther/R2_marketplace_professionalization/part1_marketplace_metadata_checks.json", JSON.stringify({ok: failed.length === 0, checks, failed}, null, 2));
if (failed.length) {
  console.log("FAILED CHECKS:");
  for (const f of failed) console.log("-", f.name, f.detail);
  process.exit(1);
}
console.log("✅ metadata checks passed:", checks.length);
NODE

echo "[5/10] VSIX package audit..."
[ -f "$VSIX.sha256" ] || sha256sum "$VSIX" > "$VSIX.sha256"
sha256sum -c "$VSIX.sha256"

python3 <<PY
from pathlib import Path
import zipfile, json

vsix = Path("$VSIX")
with zipfile.ZipFile(vsix) as z:
    names = set(z.namelist())
    lower = {n.lower(): n for n in names}
    checks = {
        "package_json": "extension/package.json" in names,
        "icon": "extension/assets/pantherlang-icon.png" in names,
        "readme": "extension/readme.md" in lower,
        "changelog": "extension/changelog.md" in lower,
        "license": any(x in lower for x in ["extension/license", "extension/license.md", "extension/license.txt"]),
    }
    pkg = json.loads(z.read("extension/package.json").decode("utf-8"))
    checks["version"] = pkg.get("version") == "1.0.0"
    checks["icon_path"] = pkg.get("icon") == "assets/pantherlang-icon.png"
    checks["banner"] = (pkg.get("galleryBanner") or {}).get("color") == "#0B1F3A"

failed = [k for k,v in checks.items() if not v]
Path(".panther/R2_marketplace_professionalization/part1_vsix_audit.json").write_text(json.dumps({
    "ok": len(failed)==0,
    "vsix": str(vsix),
    "checks": checks,
    "failed": failed
}, indent=2), encoding="utf-8")
if failed:
    raise SystemExit(f"VSIX audit failed: {failed}")
print("✅ VSIX audit passed")
PY

echo "[6/10] Creating publisher requirements checklist..."
cat > "$R2/PUBLISHER_REQUIREMENTS.md" <<'EOF'
# PantherLang VS Code Marketplace Publisher Requirements

To publish PantherLang to the VS Code Marketplace, prepare:

1. Microsoft / Azure DevOps account.
2. Visual Studio Marketplace publisher ID.
3. Personal Access Token with Marketplace Manage permission.
4. `vsce` publisher login or `VSCE_PAT` environment variable.
5. Confirm final publisher name in `vscode-extension/package.json`.

Commands later:

```bash
cd vscode-extension
npx --yes @vscode/vsce login <publisher-id>
npx --yes @vscode/vsce publish
```

Or:

```bash
cd vscode-extension
VSCE_PAT=<token> npx --yes @vscode/vsce publish
```
EOF

echo "[7/10] Creating publish gate script..."
cat > "$R2/publish_gate_command.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)/vscode-extension"

if [ -z "${VSCE_PAT:-}" ]; then
  echo "[PUBLISH-GATE][ERROR] VSCE_PAT is required for non-interactive publish."
  echo "Run:"
  echo "  VSCE_PAT=<token> npx --yes @vscode/vsce publish"
  exit 1
fi

npx --yes @vscode/vsce publish
EOF
chmod +x "$R2/publish_gate_command.sh"

echo "[8/10] Creating marketplace audit manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r2 = root / ".panther" / "R2_marketplace_professionalization"
vsix = Path("$VSIX")

manifest = {
    "ok": True,
    "phase": "R2",
    "part": "1",
    "name": "Marketplace Readiness Audit",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.0",
    "runtime_modified": False,
    "vsix": vsix.relative_to(root).as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "metadata_checks": ".panther/R2_marketplace_professionalization/part1_marketplace_metadata_checks.json",
    "vsix_audit": ".panther/R2_marketplace_professionalization/part1_vsix_audit.json",
    "publisher_requirements": ".panther/R2_marketplace_professionalization/PUBLISHER_REQUIREMENTS.md",
    "publish_gate_script": ".panther/R2_marketplace_professionalization/publish_gate_command.sh",
    "next": "R2 Part 2 - Publisher Identity + Package Finalization"
}
(r2 / "part1_marketplace_readiness_audit_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ R2 Part 1 manifest written")
PY

echo "[9/10] Writing engineering report..."
cat > "$REPORTS/R2_PART1_MARKETPLACE_READINESS_AUDIT.md" <<EOF
# R2 Part 1 - Marketplace Readiness Audit

## Status

PASSED

## Verified

- R1 final integration exists
- PantherLang v1.0.0 VSIX exists
- Production Debug Adapter regression passes
- R1 tests pass
- VS Code package metadata passes
- VSIX contents pass
- Dark-blue branding verified
- Publisher requirements checklist generated
- Publish gate command generated

## VSIX

\`$VSIX\`

## Next

R2 Part 2 - Publisher Identity + Package Finalization.
EOF

echo "[10/10] Writing status..."
cat > "$R2/status_part1_marketplace_readiness_audit.json" <<EOF
{
  "ok": true,
  "phase": "R2",
  "part": "1",
  "status": "PASSED",
  "name": "Marketplace Readiness Audit",
  "version": "1.0.0",
  "runtime_modified": false,
  "vsix": "$VSIX",
  "next": "R2 Part 2 - Publisher Identity + Package Finalization"
}
EOF

echo "============================================================"
echo "✅ R2 Part 1 COMPLETE"
echo "Next: R2 Part 2 - Publisher Identity + Package Finalization"
echo "============================================================"
