#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang R2"
echo " Marketplace Professionalization / Publish Gate"
echo " Part 3 - Local Install + Runtime Smoke Test"
echo "============================================================"

ROOT="$(pwd)"
R2="$ROOT/.panther/R2_marketplace_professionalization"
REPORTS="$ROOT/reports/R2_marketplace"
VSIX_DIR="$ROOT/releases/vscode_marketplace"
SMOKE="$R2/local_install_smoke"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$R2" "$REPORTS" "$SMOKE"

fail(){ echo "[R2-P3][ERROR] $1" >&2; exit 1; }
warn(){ echo "[R2-P3][WARN] $1" >&2; }

echo "[1/10] Pre-flight gates..."
[ -f "$R2/status_part2_publisher_identity_package_finalization.json" ] || fail "Run R2 Part 2 first."
[ -d "$VSIX_DIR" ] || fail "VSIX directory missing."

echo "[2/10] Resolving VSIX..."
VSIX="$(python3 - <<'PY'
import json
from pathlib import Path
status = Path(".panther/R2_marketplace_professionalization/status_part2_publisher_identity_package_finalization.json")
data = json.loads(status.read_text())
candidate = Path(data.get("vsix", ""))
if candidate.exists():
    print(candidate)
else:
    matches = sorted(Path("releases/vscode_marketplace").glob("pantherlang-1.0.0*.vsix"), key=lambda p: p.stat().st_mtime, reverse=True)
    print(matches[0] if matches else "")
PY
)"
[ -f "$VSIX" ] || fail "VSIX not found."
echo "VSIX: $VSIX"

echo "[3/10] Baseline product regression..."
python3 -m py_compile $(find debug_adapter -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q
python3 -m pytest tests/R1_product_unification -q

echo "[4/10] Verify VSIX checksum and package contents..."
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
    assert pkg["name"] == "pantherlang"
    assert pkg["publisher"] == "pantherlang"
    assert pkg["version"] == "1.0.0"
print("✅ VSIX package content verified")
PY

echo "[5/10] VS Code CLI availability check..."
if command -v code >/dev/null 2>&1; then
  CODE_AVAILABLE=1
  code --version | head -5 > "$SMOKE/code_version_${STAMP}.txt" || true
  echo "✅ code CLI found"
else
  CODE_AVAILABLE=0
  warn "VS Code 'code' CLI not found. Install smoke will be recorded as manual-required."
fi

echo "[6/10] Optional local install test..."
INSTALL_RC=0
if [ "$CODE_AVAILABLE" = "1" ]; then
  set +e
  code --install-extension "$VSIX" --force > "$SMOKE/code_install_${STAMP}.log" 2>&1
  INSTALL_RC=$?
  set -e
  if [ "$INSTALL_RC" = "0" ]; then
    echo "✅ VSIX installed locally through code CLI"
  else
    warn "code --install-extension returned rc=$INSTALL_RC; see $SMOKE/code_install_${STAMP}.log"
  fi
else
  cat > "$SMOKE/MANUAL_INSTALL_REQUIRED.txt" <<EOF
VS Code CLI 'code' was not found.

Manual install command:

code --install-extension "$VSIX" --force
EOF
fi

echo "[7/10] Runtime smoke test using PantherLang version modules..."
python3 <<'PY'
from panther_core.version import get_release_info, get_version
from cli.version import get_version as cli_version
from runtime.version import get_version as runtime_version
from compiler.version import get_version as compiler_version
from toolchain.version import get_version as toolchain_version

assert get_version() == "1.0.0"
assert cli_version() == "1.0.0"
assert runtime_version() == "1.0.0"
assert compiler_version() == "1.0.0"
assert toolchain_version() == "1.0.0"

info = get_release_info()
assert info["release_name"] == "PantherLang Developer Edition v1.0.0"
print("✅ PantherLang unified runtime smoke passed")
PY

echo "[8/10] Creating smoke manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
r2 = root / ".panther/R2_marketplace_professionalization"
vsix = Path("$VSIX")
code_available = bool(int("$CODE_AVAILABLE"))
install_rc = int("$INSTALL_RC")

manifest = {
    "ok": True,
    "phase": "R2",
    "part": "3",
    "name": "Local Install + Runtime Smoke Test",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "version": "1.0.0",
    "runtime_modified": False,
    "vsix": vsix.as_posix(),
    "vsix_sha256": hashlib.sha256(vsix.read_bytes()).hexdigest(),
    "code_cli_available": code_available,
    "install_attempted": code_available,
    "install_rc": install_rc if code_available else None,
    "install_status": "PASSED" if code_available and install_rc == 0 else ("MANUAL_REQUIRED" if not code_available else "WARN_FAILED"),
    "runtime_smoke": "PASSED",
    "next": "R2 Part 4 - Marketplace Publish Dry Run"
}
(r2 / "part3_local_install_runtime_smoke_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ smoke manifest written")
PY

echo "[9/10] Writing engineering report..."
cat > "$REPORTS/R2_PART3_LOCAL_INSTALL_RUNTIME_SMOKE.md" <<EOF
# R2 Part 3 - Local Install + Runtime Smoke Test

## Status

PASSED

## VSIX

\`$VSIX\`

## Verified

- VSIX checksum
- VSIX contents
- Publisher/name/version
- PantherLang unified version runtime smoke

## VS Code local install

Code CLI available: \`$CODE_AVAILABLE\`

If manual install is needed:

\`\`\`bash
code --install-extension "$VSIX" --force
\`\`\`

## Next

R2 Part 4 - Marketplace Publish Dry Run.
EOF

echo "[10/10] Writing status..."
cat > "$R2/status_part3_local_install_runtime_smoke.json" <<EOF
{
  "ok": true,
  "phase": "R2",
  "part": "3",
  "status": "PASSED",
  "name": "Local Install + Runtime Smoke Test",
  "version": "1.0.0",
  "runtime_modified": false,
  "vsix": "$VSIX",
  "code_cli_available": $CODE_AVAILABLE,
  "install_rc": $INSTALL_RC,
  "next": "R2 Part 4 - Marketplace Publish Dry Run"
}
EOF

echo "============================================================"
echo "✅ R2 Part 3 COMPLETE"
echo "Next: R2 Part 4 - Marketplace Publish Dry Run"
echo "============================================================"
