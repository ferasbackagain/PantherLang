#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 9"
echo " Part 5 - Final Certification Integration"
echo "============================================================"

ROOT="$(pwd)"
B9="$ROOT/.panther/p3_batch9_production_certification"
REPORTS="$ROOT/reports/P3/Batch9"
REL="$ROOT/releases/P3_RC"

mkdir -p "$REPORTS"

fail(){ echo "[P3-B9-P5][ERROR] $1" >&2; exit 1; }

echo "[1/8] Verifying certification gates..."
for f in \
 "$B9/status_part1_certification_audit.json" \
 "$B9/status_part2_integrity_verification.json" \
 "$B9/status_part3_reproducible_build.json" \
 "$B9/status_part4_production_readiness_certificate.json"
do
  [ -f "$f" ] || fail "Missing gate: $f"
done

echo "[2/8] Final production compile..."
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")

echo "[3/8] Final regression..."
python3 -m pytest "$ROOT/tests/P2_canonical_debug_adapter" -q

echo "[4/8] Verifying release archive..."
RC=$(ls -t "$REL"/PantherLang_RC_*.tar.gz | head -1)
sha256sum -c "${RC}.sha256"
sha512sum -c "${RC}.sha512"

echo "[5/8] Building final certification manifest..."
python3 - <<'PY'
from pathlib import Path
import json
from datetime import datetime, timezone
root=Path.cwd()
b9=root/".panther/p3_batch9_production_certification"
manifest={
 "ok":True,
 "phase":"P-3",
 "batch":"9",
 "status":"COMPLETE",
 "created_at":datetime.now(timezone.utc).isoformat(),
 "certified":True,
 "next":"P-3 Batch 10 - Official Release"
}
(b9/"batch9_final_certification_manifest.json").write_text(json.dumps(manifest,indent=2))
print("manifest written")
PY

echo "[6/8] Writing final report..."
cat > "$REPORTS/P3_BATCH9_FINAL_CERTIFICATION.md" <<EOF
# P-3 Batch 9 Final Certification

Status: PASSED

Production Certification: COMPLETE

Next:
P-3 Batch 10 - Official Release
EOF

echo "[7/8] Writing status..."
cat > "$B9/status_batch9_final.json" <<EOF
{"ok":true,"batch":"9","status":"COMPLETE","next":"P-3 Batch 10 - Official Release"}
EOF

echo "[8/8] Done."
echo "============================================================"
echo "✅ P-3 Batch 9 COMPLETE"
echo "✅ Production Certification PASSED"
echo "Next: P-3 Batch 10 - Official Release"
echo "============================================================"
