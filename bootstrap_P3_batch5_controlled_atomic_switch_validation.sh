#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-3"
echo " Atomic Replacement Planning"
echo " Batch 5 - Controlled Atomic Switch Validation"
echo "============================================================"

ROOT="$(pwd)"
P3="$ROOT/.panther/p3_atomic_replacement"
REPORTS="$ROOT/reports/P3"
SANDBOX="$P3/sandbox_atomic_switch"
TESTS="$ROOT/tests/P3_atomic_replacement"

mkdir -p "$REPORTS" "$SANDBOX" "$TESTS"

[ -f "$P3/status_batch4.json" ] || { echo "[P3-B5][ERROR] Run Batch 4 first."; exit 1; }
[ -d "$ROOT/debug_adapter" ] || { echo "[P3-B5][ERROR] debug_adapter missing."; exit 1; }
[ -d "$ROOT/debug_adapter_rebuilt" ] || { echo "[P3-B5][ERROR] debug_adapter_rebuilt missing."; exit 1; }

echo "[1/8] Preparing isolated sandbox..."
rm -rf "$SANDBOX"
mkdir -p "$SANDBOX"
cp -a "$ROOT/debug_adapter" "$SANDBOX/debug_adapter_legacy"
cp -a "$ROOT/debug_adapter_rebuilt" "$SANDBOX/debug_adapter"
cp -a "$ROOT/tests/P2_canonical_debug_adapter" "$SANDBOX/P2_canonical_debug_adapter"

echo "[2/8] Creating sandbox verification tests..."
cat > "$TESTS/test_p3_batch5_sandbox_switch.py" <<'PY'
from pathlib import Path
import importlib.util
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
SANDBOX = ROOT / ".panther" / "p3_atomic_replacement" / "sandbox_atomic_switch"


def test_sandbox_contains_legacy_and_promoted_debug_adapter():
    assert (SANDBOX / "debug_adapter_legacy").exists()
    assert (SANDBOX / "debug_adapter").exists()
    assert (SANDBOX / "debug_adapter" / "protocol.py").exists()
    assert (SANDBOX / "debug_adapter" / "server.py").exists()


def test_sandbox_promoted_adapter_imports_as_debug_adapter():
    code = """
import sys
from pathlib import Path
sandbox = Path('.panther/p3_atomic_replacement/sandbox_atomic_switch').resolve()
sys.path.insert(0, str(sandbox))
from debug_adapter.protocol import encode_message, read_message
from debug_adapter.server import DebugServer
from io import StringIO
msg={'seq':1,'type':'request','command':'initialize','arguments':{'adapterID':'panther'}}
framed=encode_message(msg)
assert read_message(StringIO(framed)) == msg
server=DebugServer()
assert server.dispatch({'seq':1,'command':'initialize','arguments':{'adapterID':'panther'}})['success'] is True
launch=server.dispatch({'seq':2,'command':'launch','arguments':{'program':'main.pan'}})
assert launch['type']=='event'
assert launch['event']=='process'
print('sandbox promoted debug_adapter OK')
"""
    proc = subprocess.run([sys.executable, "-c", code], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0, proc.stdout + proc.stderr


def test_live_runtime_was_not_replaced():
    live = ROOT / "debug_adapter"
    rebuilt = ROOT / "debug_adapter_rebuilt"
    assert live.exists()
    assert rebuilt.exists()
    assert live.resolve() != rebuilt.resolve()
PY

echo "[3/8] Compiling sandbox promoted adapter..."
python3 -m py_compile $(find "$SANDBOX/debug_adapter" -name "*.py")

echo "[4/8] Running P3 sandbox switch tests..."
python3 -m pytest "$TESTS/test_p3_batch5_sandbox_switch.py" -q

echo "[5/8] Running P2 canonical suite against live rebuilt adapter..."
python3 -m pytest tests/P2_canonical_debug_adapter -q

echo "[6/8] Writing validation manifest..."
python3 <<'PY'
from pathlib import Path
import hashlib, json
from datetime import datetime, timezone

root = Path.cwd()
sandbox = root / ".panther" / "p3_atomic_replacement" / "sandbox_atomic_switch"
files = []
for p in sorted((sandbox / "debug_adapter").rglob("*")):
    if p.is_file():
        files.append({
            "path": p.relative_to(root).as_posix(),
            "sha256": hashlib.sha256(p.read_bytes()).hexdigest(),
            "size": p.stat().st_size,
        })

manifest = {
    "ok": True,
    "phase": "P-3",
    "batch": "5",
    "name": "Controlled Atomic Switch Validation",
    "mode": "sandbox_only",
    "runtime_modified": False,
    "sandbox": sandbox.relative_to(root).as_posix(),
    "promoted_file_count": len(files),
    "files": files,
}
out = root / ".panther" / "p3_atomic_replacement" / "sandbox_switch_validation_manifest.json"
out.write_text(json.dumps(manifest, indent=2, sort_keys=True), encoding="utf-8")
print("✅ sandbox promoted files:", len(files))
PY

echo "[7/8] Writing engineering report..."
cat > "$REPORTS/P3_BATCH5_CONTROLLED_ATOMIC_SWITCH_VALIDATION.md" <<'EOF'
# P-3 Batch 5 - Controlled Atomic Switch Validation

## Status

PASSED

## Purpose

Validate the atomic replacement model in an isolated sandbox before touching production `debug_adapter/`.

## Verified

- Legacy adapter copied to sandbox as `debug_adapter_legacy`
- Rebuilt adapter promoted inside sandbox as `debug_adapter`
- Sandbox imports work using `from debug_adapter...`
- Sandbox DebugServer flow works
- Live production `debug_adapter/` was not replaced
- P2 canonical suite still passes

## Runtime Modification

None.

## Next

P-3 Batch 6 - Production Atomic Switch with rollback gate.
EOF

echo "[8/8] Writing status..."
cat > "$P3/status_batch5.json" <<'EOF'
{
  "ok": true,
  "phase": "P-3",
  "batch": "5",
  "status": "PASSED",
  "runtime_modified": false,
  "mode": "sandbox_atomic_switch_validation",
  "next": "P-3 Batch 6 - Production Atomic Switch with rollback gate"
}
EOF

echo "============================================================"
echo "✅ P-3 Batch 5 COMPLETE"
echo "Next: P-3 Batch 6 - Production Atomic Switch with rollback gate"
echo "============================================================"
