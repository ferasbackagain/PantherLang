#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 8"
echo " Part 4 - Packaging + Release Metadata"
echo "============================================================"

ROOT="$(pwd)"
B8="$ROOT/.panther/p3_batch8_release_candidate"
REPORTS="$ROOT/reports/P3/Batch8"
REL="$ROOT/releases/P3_RC"

mkdir -p "$REPORTS"

[ -f "$B8/status_part3_regression_gate.json" ] || { echo "[ERROR] Run Part 3 first."; exit 1; }

echo "[1/7] Locating latest RC..."
RC=$(ls -t "$REL"/PantherLang_RC_*.tar.gz | head -1)

echo "[2/7] Computing archive hashes..."
sha256sum "$RC" > "${RC}.sha256"
sha512sum "$RC" > "${RC}.sha512"

echo "[3/7] Collecting metadata..."
python3 - <<'PY'
from pathlib import Path
import json,hashlib
root=Path.cwd()
rel=max((root/"releases/P3_RC").glob("PantherLang_RC_*.tar.gz"), key=lambda p:p.stat().st_mtime)
meta={
 "archive":rel.name,
 "size":rel.stat().st_size,
 "sha256":hashlib.sha256(rel.read_bytes()).hexdigest(),
 "status":"RC_READY"
}
(root/".panther/p3_batch8_release_candidate/release_metadata.json").write_text(json.dumps(meta,indent=2))
print("metadata written")
PY

echo "[4/7] Verifying package..."
tar -tzf "$RC" >/dev/null

echo "[5/7] Writing release notes..."
cat > "$REPORTS/P3_BATCH8_PART4_PACKAGING.md" <<EOF
Status: PASSED

Archive: $(basename "$RC")

Metadata generated.
SHA256/SHA512 generated.

Next:
P-3 Batch 8 Part 5 - Final Integration
EOF

echo "[6/7] Writing status..."
cat > "$B8/status_part4_packaging.json" <<EOF
{"ok":true,"part":"4","status":"PASSED","next":"P-3 Batch 8 Part 5 - Final Integration"}
EOF

echo "[7/7] Done."
echo "============================================================"
echo "✅ P-3 Batch 8 Part 4 COMPLETE"
echo "Next: P-3 Batch 8 Part 5 - Final Integration"
echo "============================================================"
