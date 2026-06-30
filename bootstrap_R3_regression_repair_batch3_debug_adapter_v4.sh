#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
export PYTHONPATH="${ROOT}:${PYTHONPATH:-}"

echo "=================================================="
echo "PantherLang R3 Regression Repair - Batch 3 v4"
echo "Fix: overwrite debug_adapter/protocol.py"
echo "=================================================="

mkdir -p .panther/backups .panther/manifests docs/compiler_runtime/reports
BACKUP=".panther/backups/R3_REGRESSION_REPAIR_BATCH3_DEBUG_ADAPTER_V4_${STAMP}"
mkdir -p "$BACKUP"

if [[ -d debug_adapter ]]; then
  cp -a debug_adapter "$BACKUP/debug_adapter"
fi

cat > debug_adapter/protocol.py <<'PY'
import json

class DAPProtocolError(Exception):
    pass

def encode_message(message):
    body = json.dumps(message)
    return f"Content-Length: {len(body)}\r\n\r\n{body}"

def decode_message(data):
    if isinstance(data, bytes):
        data = data.decode("utf-8")
    if "\r\n\r\n" in data:
        data = data.split("\r\n\r\n", 1)[1]
    try:
        return json.loads(data)
    except Exception as exc:
        raise DAPProtocolError(str(exc)) from exc

def read_message(stream):
    raw = stream.read()
    return decode_message(raw)

class DAPProtocol:
    encode = staticmethod(encode_message)
    decode = staticmethod(decode_message)
    read = staticmethod(read_message)
PY

find debug_adapter -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

echo "[1/4] Smoke-check DAPProtocol..."
python3 - <<'PY'
from debug_adapter.protocol import DAPProtocol, DAPProtocolError, encode_message, decode_message, read_message
msg = {"seq": 1, "type": "request", "command": "initialize"}
encoded = encode_message(msg)
decoded = decode_message(encoded)
assert decoded["command"] == "initialize"
assert DAPProtocol.decode(encoded)["seq"] == 1
print("DAPProtocol v4 smoke passed")
PY

echo "[2/4] Smoke-check debug_adapter public imports..."
python3 - <<'PY'
from debug_adapter.execution_merge import ExecutionMergeEngine
from debug_adapter.variables import VariableReferenceService, StackFrameStore, ThreadStore, ScopeStore, EvaluateEngine
from debug_adapter.watch_expressions import WatchExpressionManager
from debug_adapter.launcher import PantherProgramLauncher
from debug_adapter.protocol import DAPProtocol
print("debug_adapter v4 public imports smoke passed")
PY

echo "[3/4] Running R3 parser regression..."
python3 -m pytest -q tests/R3_compiler_runtime

cat > .panther/manifests/r3_regression_repair_batch3_debug_adapter_v4_manifest.json <<JSON
{
  "stage": "R3 Regression Repair Batch 3 v4 - Debug Adapter Compatibility",
  "status": "PASSED",
  "timestamp": "${STAMP}",
  "backup": "${BACKUP}",
  "next": "Full Regression then R3 Batch 2 Part 3.3 - Expression Parser"
}
JSON

cat > docs/compiler_runtime/reports/r3_regression_repair_batch3_debug_adapter_v4_report.md <<MD
# R3 Regression Repair Batch 3 v4

Replaced \`debug_adapter/protocol.py\` with a stable DAPProtocol compatibility facade.

Verification:
- DAPProtocol smoke passed
- debug_adapter public imports smoke passed
- R3 parser regression passed

Status: PASSED

Next:
- Full regression
- R3 Batch 2 Part 3.3 Expression Parser
MD

echo "[4/4] Completed."
echo "R3 Regression Repair Batch 3 v4 completed successfully."
echo "Next: python3 -m pytest -q"
