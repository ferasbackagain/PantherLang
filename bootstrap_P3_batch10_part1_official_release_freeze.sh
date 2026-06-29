#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 10"
echo " Part 1 - Official Release Freeze"
echo "============================================================"

ROOT="$(pwd)"
B9="$ROOT/.panther/p3_batch9_production_certification"
B10="$ROOT/.panther/p3_batch10_official_release"
REPORTS="$ROOT/reports/P3/Batch10"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$B10" "$REPORTS"

fail(){ echo "[P3-B10-P1][ERROR] $1"; exit 1; }

echo "[1/8] Checking certification..."
[ -f "$B9/status_batch9_final.json" ] || fail "Batch 9 not complete."

echo "[2/8] Verifying production compile..."
python3 -m py_compile $(find debug_adapter -name "*.py")

echo "[3/8] Running canonical regression..."
python3 -m pytest tests/P2_canonical_debug_adapter -q

echo "[4/8] Creating official release snapshot..."
SNAP="$B10/release_freeze_${STAMP}"
mkdir -p "$SNAP"
cp -a debug_adapter "$SNAP/"
[ -d debug_adapter_rebuilt ] && cp -a debug_adapter_rebuilt "$SNAP/" || true

echo "[5/8] Creating release manifest..."
python3 - <<'PY'
from pathlib import Path
import hashlib,json
from datetime import datetime,timezone
root=Path.cwd()
snap=sorted((root/".panther/p3_batch10_official_release").glob("release_freeze_*"))[-1]
files=[]
for p in sorted(snap.rglob("*")):
    if p.is_file():
        files.append({"path":p.relative_to(root).as_posix(),
                      "sha256":hashlib.sha256(p.read_bytes()).hexdigest(),
                      "size":p.stat().st_size})
(root/".panther/p3_batch10_official_release/part1_release_manifest.json").write_text(
json.dumps({
 "ok":True,
 "phase":"P-3",
 "batch":"10",
 "part":"1",
 "name":"Official Release Freeze",
 "created_at":datetime.now(timezone.utc).isoformat(),
 "files":files,
 "next":"P-3 Batch 10 Part 2 - Version Stamping"
},indent=2))
print("files:",len(files))
PY

echo "[6/8] Writing report..."
cat > "$REPORTS/P3_BATCH10_PART1_RELEASE_FREEZE.md" <<EOF
Status: PASSED

Official release freeze completed.

Next:
P-3 Batch 10 Part 2 - Version Stamping
EOF

echo "[7/8] Writing status..."
cat > "$B10/status_part1_release_freeze.json" <<EOF
{"ok":true,"batch":"10","part":"1","status":"PASSED","next":"P-3 Batch 10 Part 2 - Version Stamping"}
EOF

echo "[8/8] Complete."
echo "============================================================"
echo "✅ P-3 Batch 10 Part 1 COMPLETE"
echo "Next: P-3 Batch 10 Part 2 - Version Stamping"
echo "============================================================"
