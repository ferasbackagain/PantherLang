#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3"
echo " Atomic Replacement Planning"
echo " Batch 6 - Production Atomic Switch with Rollback Gate"
echo "============================================================"

ROOT="$(pwd)"
P3="$ROOT/.panther/p3_atomic_replacement"
REPORTS="$ROOT/reports/P3"
BACKUPS="$ROOT/.panther/backups"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$BACKUPS/P3_Batch6_pre_atomic_switch_${STAMP}"

mkdir -p "$P3" "$REPORTS" "$BACKUPS" "$BACKUP_DIR"

fail(){ echo "[P3-B6][ERROR] $1" >&2; exit 1; }

[ -f "$P3/status_batch5.json" ] || fail "Run P-3 Batch 5 first."
[ -d "$ROOT/debug_adapter" ] || fail "debug_adapter missing."
[ -d "$ROOT/debug_adapter_rebuilt" ] || fail "debug_adapter_rebuilt missing."

echo "[1/10] Pre-flight compile and tests on rebuilt adapter..."
python3 -m py_compile $(find "$ROOT/debug_adapter_rebuilt" -name "*.py")
python3 -m pytest tests/P2_canonical_debug_adapter -q

echo "[2/10] Creating full rollback backup..."
cp -a "$ROOT/debug_adapter" "$BACKUP_DIR/debug_adapter_legacy_before_switch"
cp -a "$ROOT/debug_adapter_rebuilt" "$BACKUP_DIR/debug_adapter_rebuilt_source"
tar -czf "$BACKUP_DIR/debug_adapter_legacy_before_switch.tar.gz" -C "$BACKUP_DIR" debug_adapter_legacy_before_switch

echo "[3/10] Writing rollback script..."
cat > "$BACKUP_DIR/rollback_P3_batch6.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ROOT="\$(pwd)"
echo "Rolling back P-3 Batch 6..."
[ -d "$BACKUP_DIR/debug_adapter_legacy_before_switch" ] || { echo "rollback source missing"; exit 1; }
rm -rf "\$ROOT/debug_adapter"
cp -a "$BACKUP_DIR/debug_adapter_legacy_before_switch" "\$ROOT/debug_adapter"
python3 -m py_compile \$(find "\$ROOT/debug_adapter" -name "*.py")
echo "✅ rollback complete"
EOF
chmod +x "$BACKUP_DIR/rollback_P3_batch6.sh"

echo "[4/10] Performing atomic switch..."
rm -rf "$ROOT/debug_adapter_legacy_P3_${STAMP}"
mv "$ROOT/debug_adapter" "$ROOT/debug_adapter_legacy_P3_${STAMP}"
cp -a "$ROOT/debug_adapter_rebuilt" "$ROOT/debug_adapter"

echo "[5/10] Validating promoted production debug_adapter..."
python3 -m py_compile $(find "$ROOT/debug_adapter" -name "*.py")

echo "[6/10] Running production smoke verification..."
python3 <<'PY'
from io import StringIO, BytesIO
from debug_adapter.protocol import encode_message, read_message
from debug_adapter.server import DebugServer

msg = {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}}
frame = encode_message(msg)
assert read_message(StringIO(frame)) == msg
assert read_message(BytesIO(bytes(frame))) == msg

server = DebugServer()
init = server.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})
assert init["success"] is True
launch = server.dispatch({"seq": 2, "command": "launch", "arguments": {"program": "main.pan"}})
assert launch["type"] == "event"
assert launch["event"] == "process"
print("✅ promoted production debug_adapter smoke passed")
PY

echo "[7/10] Running P2 canonical tests against production package name..."
mkdir -p tests/P3_atomic_replacement
cat > tests/P3_atomic_replacement/test_p3_batch6_production_debug_adapter.py <<'PY'
from io import StringIO, BytesIO

from debug_adapter.protocol import encode_message, read_message
from debug_adapter.server import DebugServer
from debug_adapter.request_dispatcher import RequestDispatcher
from debug_adapter.variable_store import VariableStore
from debug_adapter.evaluate import EvaluateEngine


def test_production_debug_adapter_protocol_and_server():
    msg = {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}}
    framed = encode_message(msg)
    assert read_message(StringIO(framed)) == msg
    assert read_message(BytesIO(bytes(framed))) == msg

    server = DebugServer()
    assert server.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
    launch = server.dispatch({"seq": 2, "command": "launch", "arguments": {"program": "main.pan"}})
    assert launch["type"] == "event"
    assert launch["event"] == "process"


def test_production_dispatcher_and_data_model():
    d = RequestDispatcher()
    assert d.dispatch({"seq": 1, "command": "initialize", "arguments": {}})["success"] is True
    assert d.dispatch({"seq": 2, "command": "configurationDone"})["success"] is True
    assert d.dispatch({"seq": 3, "command": "launch", "arguments": {"program": "x.pan"}})["event"] == "process"

    store = VariableStore()
    store.set("x", 7)
    assert store.get("x").value == "7"
    assert EvaluateEngine({"x": 7}).evaluate("x + 1").result == "8"
PY

python3 -m pytest tests/P3_atomic_replacement/test_p3_batch6_production_debug_adapter.py -q

echo "[8/10] Writing switch manifest..."
python3 <<PY
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
backup_dir = Path("$BACKUP_DIR")
files = []
for p in sorted((root / "debug_adapter").rglob("*")):
    if p.is_file():
        files.append({
            "path": p.relative_to(root).as_posix(),
            "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
            "size": p.stat().st_size
        })

manifest = {
    "ok": True,
    "phase": "P-3",
    "batch": "6",
    "name": "Production Atomic Switch with Rollback Gate",
    "created_at": datetime.now(timezone.utc).isoformat(),
    "runtime_modified": True,
    "promoted": "debug_adapter_rebuilt -> debug_adapter",
    "legacy_moved_to": "debug_adapter_legacy_P3_${STAMP}",
    "rollback_dir": str(backup_dir.relative_to(root)),
    "rollback_script": str((backup_dir / "rollback_P3_batch6.sh").relative_to(root)),
    "promoted_file_count": len(files),
    "files": files
}
(root / ".panther" / "p3_atomic_replacement" / "production_atomic_switch_manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ promoted files:", len(files))
PY

echo "[9/10] Writing engineering report..."
cat > "$REPORTS/P3_BATCH6_PRODUCTION_ATOMIC_SWITCH.md" <<EOF
# P-3 Batch 6 - Production Atomic Switch with Rollback Gate

## Status

PASSED

## What Happened

Production \`debug_adapter/\` was atomically replaced with the canonical rebuilt adapter.

Legacy adapter was moved to:

\`debug_adapter_legacy_P3_${STAMP}\`

Rollback package:

\`$BACKUP_DIR\`

Rollback command:

\`\`\`bash
cd ~/pantherlang/PantherLang_Developer_Edition_v0_5
bash $BACKUP_DIR/rollback_P3_batch6.sh
\`\`\`

## Verified

- Rebuilt adapter compiled before switch
- P2 canonical suite passed before switch
- Legacy adapter backed up
- Atomic switch completed
- Promoted production adapter compiled
- Production smoke test passed
- Production package-name tests passed

## Next

P-3 Batch 7 - Full H4 Compatibility Regression + Final Release Candidate.
EOF

echo "[10/10] Writing status..."
cat > "$P3/status_batch6.json" <<EOF
{
  "ok": true,
  "phase": "P-3",
  "batch": "6",
  "status": "PASSED",
  "runtime_modified": true,
  "legacy_moved_to": "debug_adapter_legacy_P3_${STAMP}",
  "rollback_dir": "$BACKUP_DIR",
  "next": "P-3 Batch 7 - Full H4 Compatibility Regression + Final Release Candidate"
}
EOF

echo "============================================================"
echo "✅ P-3 Batch 6 COMPLETE"
echo "✅ Production debug_adapter replaced with canonical rebuilt adapter"
echo "Next: P-3 Batch 7 - Full H4 Compatibility Regression + Final Release Candidate"
echo "============================================================"
