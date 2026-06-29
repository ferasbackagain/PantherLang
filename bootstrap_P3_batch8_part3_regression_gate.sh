#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3 Batch 8"
echo " Part 3 - Release Candidate Regression Gate"
echo "============================================================"

ROOT="$(pwd)"
B8="$ROOT/.panther/p3_batch8_release_candidate"
REPORTS="$ROOT/reports/P3/Batch8"
RELEASES="$ROOT/releases/P3_RC"
STAMP="$(date +%Y%m%d_%H%M%S)"

mkdir -p "$REPORTS"

fail(){ echo "[P3-B8-P3][ERROR] $1" >&2; exit 1; }

echo "[1/9] Pre-flight gates..."
[ -f "$B8/status_part1_release_freeze.json" ] || fail "Part 1 status missing."
[ -f "$B8/status_part2_artifact_assembly.json" ] || fail "Part 2 status missing."
[ -d "$ROOT/debug_adapter" ] || fail "production debug_adapter missing."
[ -d "$ROOT/debug_adapter_rebuilt" ] || fail "debug_adapter_rebuilt missing."
[ -d "$ROOT/tests/P2_canonical_debug_adapter" ] || fail "P2 canonical tests missing."

echo "[2/9] Resolving latest RC archive..."
RC_ARCHIVE="$(python3 - <<'PY'
import json
from pathlib import Path

status = Path(".panther/p3_batch8_release_candidate/status_part2_artifact_assembly.json")
data = json.loads(status.read_text())
archive = Path(data.get("archive", ""))
if not archive.exists():
    candidates = sorted(Path("releases/P3_RC").glob("PantherLang_RC_*.tar.gz"), key=lambda p: p.stat().st_mtime, reverse=True)
    archive = candidates[0] if candidates else archive
print(archive)
PY
)"
[ -f "$RC_ARCHIVE" ] || fail "RC archive not found: $RC_ARCHIVE"
echo "RC archive: $RC_ARCHIVE"

echo "[3/9] Creating isolated RC regression workspace..."
WORK="$B8/part3_regression_workspace_${STAMP}"
rm -rf "$WORK"
mkdir -p "$WORK"
tar -xzf "$RC_ARCHIVE" -C "$WORK"

echo "[4/9] Static compile production and extracted RC..."
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")
python3 -m py_compile $(find "$WORK" -name "*.py")

echo "[5/9] Running production regression gates..."
python3 -m pytest "$ROOT/tests/P2_canonical_debug_adapter" -q

if [ -d "$ROOT/tests/P3_atomic_replacement" ]; then
  python3 -m pytest "$ROOT/tests/P3_atomic_replacement" -q
fi

echo "[6/9] Running extracted RC import smoke..."
python3 <<PY
import sys
from pathlib import Path
from io import StringIO, BytesIO

work = Path("$WORK").resolve()
candidates = list(work.rglob("debug_adapter"))
assert candidates, "No debug_adapter found inside extracted RC"
pkg_parent = candidates[0].parent
sys.path.insert(0, str(pkg_parent))

from debug_adapter.protocol import encode_message, read_message
from debug_adapter.server import DebugServer

msg = {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}}
frame = encode_message(msg)
assert read_message(StringIO(frame)) == msg
assert read_message(BytesIO(bytes(frame))) == msg

server = DebugServer()
assert server.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
launch = server.dispatch({"seq": 2, "command": "launch", "arguments": {"program": "rc.pan"}})
assert launch["type"] == "event"
assert launch["event"] == "process"
print("✅ extracted RC smoke passed")
PY

echo "[7/9] Generating regression gate result..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
b8 = root / ".panther" / "p3_batch8_release_candidate"
work = Path("$WORK")
archive = Path("$RC_ARCHIVE")

files = []
for p in sorted(work.rglob("*")):
    if p.is_file():
        files.append({
            "path": p.relative_to(root).as_posix(),
            "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
            "size": p.stat().st_size,
        })

result = {
    "ok": True,
    "phase": "P-3",
    "batch": "8",
    "part": "3",
    "name": "Release Candidate Regression Gate",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": False,
    "rc_archive": archive.as_posix(),
    "workspace": work.relative_to(root).as_posix(),
    "verified": [
        "production_py_compile",
        "rc_py_compile",
        "p2_canonical_regression",
        "p3_atomic_replacement_regression_if_present",
        "extracted_rc_import_smoke"
    ],
    "extracted_file_count": len(files),
    "files": files
}
(b8 / "part3_regression_gate_result.json").write_text(json.dumps(result, indent=2, sort_keys=True), encoding="utf-8")
print("✅ extracted RC files:", len(files))
PY

echo "[8/9] Writing engineering report..."
cat > "$REPORTS/P3_BATCH8_PART3_REGRESSION_GATE.md" <<EOF
# P-3 Batch 8 Part 3 - Release Candidate Regression Gate

## Status

PASSED

## RC Archive

\`$RC_ARCHIVE\`

## Verified

- Production debug_adapter compile passed
- Extracted RC compile passed
- P2 canonical regression passed
- P3 atomic replacement regression passed if present
- Extracted RC import smoke passed

## Runtime Modification

No runtime source files were modified.

## Result

\`.panther/p3_batch8_release_candidate/part3_regression_gate_result.json\`

## Next

P-3 Batch 8 Part 4 - Packaging + Release Metadata.
EOF

echo "[9/9] Writing status..."
cat > "$B8/status_part3_regression_gate.json" <<EOF
{
  "ok": true,
  "phase": "P-3",
  "batch": "8",
  "part": "3",
  "status": "PASSED",
  "name": "Release Candidate Regression Gate",
  "runtime_modified": false,
  "rc_archive": "$RC_ARCHIVE",
  "result": ".panther/p3_batch8_release_candidate/part3_regression_gate_result.json",
  "next": "P-3 Batch 8 Part 4 - Packaging + Release Metadata"
}
EOF

echo "============================================================"
echo "✅ P-3 Batch 8 Part 3 COMPLETE"
echo "Next: P-3 Batch 8 Part 4 - Packaging + Release Metadata"
echo "============================================================"
