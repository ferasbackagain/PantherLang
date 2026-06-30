#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
export PYTHONPATH="${ROOT}:${PYTHONPATH:-}"

echo "=================================================="
echo "PantherLang R3 Regression Repair - Batch 3 v3"
echo "Fix: force DAPProtocol facade"
echo "=================================================="

mkdir -p .panther/backups .panther/manifests docs/compiler_runtime/reports
BACKUP=".panther/backups/R3_REGRESSION_REPAIR_BATCH3_DEBUG_ADAPTER_V3_${STAMP}"
mkdir -p "$BACKUP"

if [[ -d debug_adapter ]]; then
  cp -a debug_adapter "$BACKUP/debug_adapter"
fi

python3 <<'PY'
from pathlib import Path

p = Path("debug_adapter/protocol.py")
p.parent.mkdir(parents=True, exist_ok=True)

text = p.read_text(encoding="utf-8") if p.exists() else ""

if "class DAPProtocolError" not in text:
    text += '''

class DAPProtocolError(Exception):
    pass
'''

if "def encode_message" not in text:
    text += r'''

def encode_message(message):
    import json
    body = json.dumps(message)
    return f"Content-Length: {len(body)}\r\n\r\n{body}"
'''

if "def decode_message" not in text:
    text += r'''

def decode_message(data):
    import json
    if "\r\n\r\n" in data:
        data = data.split("\r\n\r\n", 1)[1]
    return json.loads(data)
'''

if "def read_message" not in text:
    text += r'''

def read_message(stream):
    return decode_message(stream.read())
'''

if "class DAPProtocol" not in text:
    text += '''

class DAPProtocol:
    encode = staticmethod(encode_message)
    decode = staticmethod(decode_message)
    read = staticmethod(read_message)
'''

p.write_text(text, encoding="utf-8")
PY

echo "[1/4] Smoke-check DAPProtocol..."
python3 - <<'PY'
from debug_adapter.protocol import DAPProtocol, DAPProtocolError, encode_message, read_message
assert DAPProtocol is not None
assert DAPProtocolError is not None
assert callable(encode_message)
assert callable(read_message)
print("DAPProtocol v3 smoke passed")
PY

echo "[2/4] Smoke-check debug_adapter public imports..."
python3 - <<'PY'
from debug_adapter.execution_merge import ExecutionMergeEngine
from debug_adapter.variables import VariableReferenceService, StackFrameStore, ThreadStore, ScopeStore, EvaluateEngine
from debug_adapter.watch_expressions import WatchExpressionManager
from debug_adapter.launcher import PantherProgramLauncher
from debug_adapter.protocol import DAPProtocol
print("debug_adapter v3 public imports smoke passed")
PY

echo "[3/4] Running R3 parser regression..."
python3 -m pytest -q tests/R3_compiler_runtime

cat > .panther/manifests/r3_regression_repair_batch3_debug_adapter_v3_manifest.json <<JSON
{
  "stage": "R3 Regression Repair Batch 3 v3 - Debug Adapter Compatibility",
  "status": "PASSED",
  "timestamp": "${STAMP}",
  "backup": "${BACKUP}",
  "next": "Full Regression or R3 Batch 2 Part 3.3 - Expression Parser"
}
JSON

cat > docs/compiler_runtime/reports/r3_regression_repair_batch3_debug_adapter_v3_report.md <<MD
# R3 Regression Repair Batch 3 v3

Fixed DAPProtocol facade in debug_adapter.protocol.

Verification:
- DAPProtocol smoke passed
- debug_adapter public imports smoke passed
- R3 parser regression passed

Status: PASSED

Next:
- Full Regression
- Then R3 Batch 2 Part 3.3 Expression Parser
MD

echo "[4/4] Completed."
echo "R3 Regression Repair Batch 3 v3 completed successfully."
echo "Manifest: .panther/manifests/r3_regression_repair_batch3_debug_adapter_v3_manifest.json"
echo "Report: docs/compiler_runtime/reports/r3_regression_repair_batch3_debug_adapter_v3_report.md"
echo "Backup: ${BACKUP}"
echo "Next: run full regression: python3 -m pytest -q"
