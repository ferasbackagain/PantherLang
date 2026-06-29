#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " Panther Recovery Engine"
echo " P-1 Batch 1 - Workspace Census"
echo "============================================================"

ROOT="$(pwd)"
OUT="$ROOT/.panther/recovery"
mkdir -p "$OUT"

echo "[1/6] Discovering workspace..."
find "$ROOT" -type f > "$OUT/all_files.txt"

echo "[2/6] Locating debug_adapter copies..."
find "$ROOT" -type d -name debug_adapter > "$OUT/debug_adapter_locations.txt"

echo "[3/6] Hashing Python files..."
python3 <<'PY'
from pathlib import Path
import hashlib, json

root=Path.cwd()
out=root/".panther"/"recovery"
rows=[]
for d in root.rglob("debug_adapter"):
    if d.is_dir():
        for f in d.rglob("*.py"):
            rows.append({
                "path":str(f.relative_to(root)),
                "sha256":hashlib.sha256(f.read_bytes()).hexdigest(),
                "size":f.stat().st_size,
            })
(out/"debug_adapter_manifest.json").write_text(json.dumps(rows,indent=2))
print(f"Indexed {len(rows)} python files.")
PY

echo "[4/6] Detecting duplicate hashes..."
python3 <<'PY'
from pathlib import Path
import json
from collections import defaultdict

m=json.loads((Path(".panther/recovery")/"debug_adapter_manifest.json").read_text())
dup=defaultdict(list)
for r in m:
    dup[r["sha256"]].append(r["path"])
dup={k:v for k,v in dup.items() if len(v)>1}
(Path(".panther/recovery")/"duplicate_groups.json").write_text(json.dumps(dup,indent=2))
print(f"Duplicate groups: {len(dup)}")
PY

echo "[5/6] Writing engineering report..."
cat > "$OUT/WORKSPACE_CENSUS.md" <<EOF
# Panther Recovery Engine - P-1 Batch 1

Status: COMPLETE

Artifacts:
- all_files.txt
- debug_adapter_locations.txt
- debug_adapter_manifest.json
- duplicate_groups.json

No project files were modified.
EOF

cat > "$OUT/status.json" <<EOF
{
  "phase":"P-1",
  "batch":"1",
  "status":"COMPLETE",
  "next":"P-1 Batch 2 - Canonical Baseline"
}
EOF

echo "[6/6] Done."
echo "============================================================"
echo "✅ P-1 Batch 1 COMPLETE"
echo "Next: P-1 Batch 2 - Canonical Baseline"
echo "============================================================"
