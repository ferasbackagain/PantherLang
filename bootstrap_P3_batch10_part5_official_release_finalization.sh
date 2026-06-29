#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 10"
echo " Part 5 - Official Release Finalization"
echo "============================================================"

ROOT="$(pwd)"
B10="$ROOT/.panther/p3_batch10_official_release"
REL="$ROOT/releases/P3_OFFICIAL"
REPORTS="$ROOT/reports/P3/Batch10"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$REPORTS"

fail(){ echo "[P3-B10-P5][ERROR] $1"; exit 1; }

for f in \
 "$B10/status_part1_release_freeze.json" \
 "$B10/status_part2_version_stamping.json" \
 "$B10/status_part3_final_release_manifest.json" \
 "$B10/status_part4_official_release_package.json"
do
  [ -f "$f" ] || fail "Missing prerequisite: $f"
done

echo "[1/8] Final compile..."
python3 -m py_compile $(find debug_adapter -name "*.py")

echo "[2/8] Final regression..."
python3 -m pytest tests/P2_canonical_debug_adapter -q

echo "[3/8] Verifying official package..."
PKG=$(ls -t "$REL"/PantherLang_Debug_Adapter_*.tar.gz | head -1)
[ -f "$PKG" ] || fail "Official package not found."
sha256sum -c "$PKG.sha256"
sha512sum -c "$PKG.sha512"

echo "[4/8] Creating release completion marker..."
cat > "$B10/OFFICIAL_RELEASE_COMPLETE.txt" <<EOF
PantherLang Debug Adapter Official Release
Completed: $STAMP
Package: $PKG
EOF

echo "[5/8] Writing final manifest..."
python3 - <<'PY'
from pathlib import Path
import json
from datetime import datetime, timezone
root=Path.cwd()
b10=root/".panther/p3_batch10_official_release"
manifest={
 "ok":True,
 "phase":"P-3",
 "batch":"10",
 "status":"COMPLETE",
 "official_release":True,
 "completed_at":datetime.now(timezone.utc).isoformat(),
 "next":"PantherLang Next Development Cycle"
}
(b10/"OFFICIAL_RELEASE_MANIFEST.json").write_text(json.dumps(manifest,indent=2))
print("manifest written")
PY

echo "[6/8] Engineering report..."
cat > "$REPORTS/P3_BATCH10_OFFICIAL_RELEASE_FINALIZATION.md" <<EOF
Status: PASSED

Official Release finalized.

P-2: COMPLETE
P-3: COMPLETE

Next:
PantherLang next development cycle.
EOF

echo "[7/8] Writing status..."
echo '{"ok":true,"batch":"10","status":"COMPLETE","official_release":true}' > "$B10/status_batch10_final.json"

echo "[8/8] Done."
echo "============================================================"
echo "✅ P-3 Batch 10 COMPLETE"
echo "✅ OFFICIAL RELEASE FINALIZED"
echo "============================================================"
