#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 8"
echo " Part 2 - Release Candidate Artifact Assembly"
echo "============================================================"

ROOT="$(pwd)"
B8="$ROOT/.panther/p3_batch8_release_candidate"
REPORTS="$ROOT/reports/P3/Batch8"
RCROOT="$ROOT/releases/P3_RC"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$REPORTS" "$RCROOT"

[ -f "$B8/status_part1_release_freeze.json" ] || { echo "[ERROR] Run Part 1 first."; exit 1; }

echo "[1/8] Creating RC workspace..."
RC="$RCROOT/PantherLang_RC_${STAMP}"
mkdir -p "$RC"

echo "[2/8] Collecting artifacts..."
cp -a debug_adapter "$RC/"
cp -a debug_adapter_rebuilt "$RC/"
[ -d debug_adapter_bridge ] && cp -a debug_adapter_bridge "$RC/" || true
cp -a .panther/p3_batch8_release_candidate/part1_release_freeze_manifest.json "$RC/" || true

echo "[3/8] Static validation..."
python3 -m py_compile $(find "$RC/debug_adapter" -name "*.py")
python3 -m py_compile $(find "$RC/debug_adapter_rebuilt" -name "*.py")

echo "[4/8] Running canonical regression..."
python3 -m pytest tests/P2_canonical_debug_adapter -q

echo "[5/8] Building artifact manifest..."
python3 - <<'PY'
from pathlib import Path
import hashlib,json
root=Path.cwd()
rc=sorted((root/"releases/P3_RC").glob("PantherLang_RC_*"))[-1]
rows=[]
for p in sorted(rc.rglob("*")):
    if p.is_file():
        rows.append({"path":p.relative_to(root).as_posix(),
                     "sha256":hashlib.sha256(p.read_bytes()).hexdigest(),
                     "size":p.stat().st_size})
(rc/"artifact_manifest.json").write_text(json.dumps({"files":rows},indent=2))
print("files:",len(rows))
PY

echo "[6/8] Packaging RC..."
tar -czf "$RC.tar.gz" -C "$RCROOT" "$(basename "$RC")"

echo "[7/8] Writing report..."
cat > "$REPORTS/P3_BATCH8_PART2_ARTIFACT_ASSEMBLY.md" <<EOF
Status: PASSED

Release Candidate artifacts assembled.

Archive:
${RC}.tar.gz

Next:
P-3 Batch 8 Part 3 - Release Candidate Regression Gate
EOF

echo "[8/8] Writing status..."
cat > "$B8/status_part2_artifact_assembly.json" <<EOF
{
 "ok":true,
 "part":"2",
 "status":"PASSED",
 "archive":"${RC}.tar.gz",
 "next":"P-3 Batch 8 Part 3 - Release Candidate Regression Gate"
}
EOF

echo "============================================================"
echo "✅ P-3 Batch 8 Part 2 COMPLETE"
echo "Next: P-3 Batch 8 Part 3 - Release Candidate Regression Gate"
echo "============================================================"
