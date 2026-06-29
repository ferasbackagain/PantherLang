#!/usr/bin/env bash
set -euo pipefail
echo "============================================================"
echo " PantherLang P-3 Batch 10"
echo " Part 4 - Official Release Package"
echo "============================================================"

ROOT="$(pwd)"
B10="$ROOT/.panther/p3_batch10_official_release"
REL="$ROOT/releases/P3_OFFICIAL"
REPORTS="$ROOT/reports/P3/Batch10"
STAMP="$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REL" "$REPORTS"

test -f "$B10/status_part3_final_release_manifest.json"

VERSION=$(python3 - <<'PY'
import json
from pathlib import Path
print(json.loads(Path(".panther/p3_batch10_official_release/OFFICIAL_DEBUG_ADAPTER_VERSION.json").read_text())["version"])
PY
)

PKG="$REL/PantherLang_Debug_Adapter_${VERSION}_${STAMP}.tar.gz"

echo "[1/7] Compile..."
python3 -m py_compile $(find debug_adapter -name "*.py")

echo "[2/7] Canonical regression..."
python3 -m pytest tests/P2_canonical_debug_adapter -q

echo "[3/7] Creating official package..."
tar -czf "$PKG" debug_adapter .panther/p3_batch10_official_release reports/P3/Batch10

echo "[4/7] Signing package hashes..."
sha256sum "$PKG" > "$PKG.sha256"
sha512sum "$PKG" > "$PKG.sha512"

echo "[5/7] Verifying..."
sha256sum -c "$PKG.sha256"
sha512sum -c "$PKG.sha512"

echo "[6/7] Report..."
cat > "$REPORTS/P3_BATCH10_PART4_OFFICIAL_PACKAGE.md" <<EOF
Status: PASSED

Official package:
$PKG

Next:
P-3 Batch 10 Part 5 - Official Release Finalization
EOF

echo '{"ok":true,"part":"4","status":"PASSED","package":"'"$PKG"'","next":"P-3 Batch 10 Part 5 - Official Release Finalization"}' > "$B10/status_part4_official_release_package.json"

echo "[7/7] Done."
echo "============================================================"
echo "✅ P-3 Batch 10 Part 4 COMPLETE"
echo "Next: P-3 Batch 10 Part 5 - Official Release Finalization"
echo "============================================================"
