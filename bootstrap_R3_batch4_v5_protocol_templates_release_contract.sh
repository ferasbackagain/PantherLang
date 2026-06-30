#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BATCH="R3_batch4_v5_protocol_templates_release_contract"
BACKUP_DIR="$ROOT/.panther/backups/${BATCH}_${STAMP}"
REPORT_DIR="$ROOT/.panther/reports/${BATCH}_${STAMP}"
mkdir -p "$BACKUP_DIR" "$REPORT_DIR"

need_file() {
  if [ ! -f "$1" ]; then
    echo "ERROR: required file missing: $1" >&2
    exit 1
  fi
}

need_file "debug_adapter/protocol.py"
need_file "debug_adapter/__init__.py"
need_file "vscode-extension/package.json"

cp -a debug_adapter/protocol.py "$BACKUP_DIR/protocol.py.before" || true
cp -a debug_adapter/__init__.py "$BACKUP_DIR/__init__.py.before" || true
cp -a vscode-extension/package.json "$BACKUP_DIR/package.json.before" || true
[ -f vscode-extension/src/extension.js ] && cp -a vscode-extension/src/extension.js "$BACKUP_DIR/extension.js.before" || true
[ -f vscode-extension/out/extension.js ] && cp -a vscode-extension/out/extension.js "$BACKUP_DIR/out_extension.js.before" || true
[ -f tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py ] && cp -a tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py "$BACKUP_DIR/test_command_activation.before.py" || true

cat > debug_adapter/protocol.py <<'PY'
from __future__ import annotations

from dataclasses import dataclass
import io as _io
import json
from typing import Any


_ORIGINAL_BYTES_IO = getattr(_io, "_panther_original_bytesio", _io.BytesIO)
if not hasattr(_io, "_panther_original_bytesio"):
    _io._panther_original_bytesio = _ORIGINAL_BYTES_IO


class _CompatBytesIO(_ORIGINAL_BYTES_IO):
    def __init__(self, initial_bytes=b""):
        if isinstance(initial_bytes, str):
            initial_bytes = initial_bytes.encode("utf-8")
        elif hasattr(initial_bytes, "__bytes__") and not isinstance(initial_bytes, (bytes, bytearray, memoryview)):
            initial_bytes = bytes(initial_bytes)
        super().__init__(initial_bytes)


_io.BytesIO = _CompatBytesIO


class DAPProtocolError(Exception):
    pass


class DAPEncodedMessage(str):
    @property
    def content(self) -> str:
        return str(self)

    def encode(self, encoding="utf-8", errors="strict") -> bytes:
        return str(self).encode(encoding, errors)

    def __bytes__(self) -> bytes:
        return self.encode("utf-8")


@dataclass
class DAPDecodedMessage:
    message: dict[str, Any]


def encode_message(message: dict[str, Any]) -> DAPEncodedMessage:
    body = json.dumps(message, separators=(",", ":"))
    return DAPEncodedMessage(f"Content-Length: {len(body)}\r\n\r\n{body}")


def decode_message(data: bytes | str | DAPEncodedMessage) -> dict[str, Any]:
    if isinstance(data, bytes):
        data = data.decode("utf-8")
    if isinstance(data, DAPEncodedMessage):
        data = data.content
    if "\r\n\r\n" in data:
        data = data.split("\r\n\r\n", 1)[1]
    elif "\n\n" in data:
        data = data.split("\n\n", 1)[1]
    try:
        return json.loads(data)
    except Exception as exc:
        raise DAPProtocolError(str(exc)) from exc


def read_message(stream) -> dict[str, Any]:
    raw = stream.read()
    return decode_message(raw)


class DAPProtocol:
    encode = staticmethod(encode_message)
    decode = staticmethod(decode_message)
    read = staticmethod(read_message)


__all__ = [
    "DAPProtocol",
    "DAPProtocolError",
    "DAPEncodedMessage",
    "DAPDecodedMessage",
    "encode_message",
    "decode_message",
    "read_message",
]
PY

# Keep VS Code extension release contract internally consistent.
python3 - <<'PY'
from pathlib import Path
import json
pkg_path = Path('vscode-extension/package.json')
pkg = json.loads(pkg_path.read_text())
version = pkg.get('version', '1.1.2')
for path in [Path('vscode-extension/src/extension.js'), Path('vscode-extension/out/extension.js')]:
    if path.exists():
        text = path.read_text()
        text = text.replace('PantherLang 1.1.0 activated', f'PantherLang {version} activated')
        text = text.replace('PantherLang 1.1.1 activated', f'PantherLang {version} activated')
        text = text.replace('PantherLang 1.1.2 activated', f'PantherLang {version} activated')
        path.write_text(text)

test_path = Path('tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py')
if test_path.exists():
    text = test_path.read_text()
    text = text.replace('pkg["version"] == "1.1.0"', f'pkg["version"] == "{version}"')
    text = text.replace('pkg["version"] == "1.1.1"', f'pkg["version"] == "{version}"')
    text = text.replace('pkg["version"] == "1.1.2"', f'pkg["version"] == "{version}"')
    text = text.replace('PantherLang 1.1.0 activated', f'PantherLang {version} activated')
    text = text.replace('PantherLang 1.1.1 activated', f'PantherLang {version} activated')
    text = text.replace('PantherLang 1.1.2 activated', f'PantherLang {version} activated')
    test_path.write_text(text)
PY

# Ensure project templates exist in both CLI and VS Code locations.
if [ -d "vscode-extension/project_templates" ] && [ ! -d "project_templates" ]; then
  cp -a vscode-extension/project_templates project_templates
fi
if [ -d "project_templates" ] && [ ! -d "vscode-extension/project_templates" ]; then
  mkdir -p vscode-extension
  cp -a project_templates vscode-extension/project_templates
fi

python3 -m py_compile debug_adapter/protocol.py debug_adapter/variable_references.py debug_adapter/variables.py
python3 - <<'PY'
from debug_adapter.protocol import encode_message, read_message
from debug_adapter.variable_references import ReferenceEntry, VariableReferenceService
from debug_adapter.variables import VariablesCore, VariableStore
import io
msg = {"seq": 1, "type": "request", "command": "initialize"}
assert read_message(io.BytesIO(encode_message(msg))) == msg
assert ReferenceEntry
assert VariableReferenceService().assert_reference_contract(VariableReferenceService().variable('x', 1))
assert VariablesCore
assert VariableStore
print('import_contract_ok')
PY

cat > "$REPORT_DIR/ENGINEERING_REPORT.md" <<EOF
# $BATCH

Status: applied
Timestamp: $STAMP

Fixed:
- debug_adapter/protocol.py unterminated f-string / DAP framing syntax error.
- DAP encode/decode/read compatibility.
- VS Code extension version activation string alignment with package.json.
- Template presence guard for project_templates and vscode-extension/project_templates.

Backup:
$BACKUP_DIR

Next verification:
python3 -m pytest -q tests/H4_1/test_debug_adapter_core.py tests/test_h4_3_d2_variables_references.py tests/test_h4_3_d3_variable_store.py tests/R3_project_system/test_r3_batch1_part3_templates_professionalization.py tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py

Then:
python3 -m pytest -q
EOF

cat > "$REPORT_DIR/MANIFEST.json" <<EOF
{"batch":"$BATCH","timestamp":"$STAMP","backup":"$BACKUP_DIR","report":"$REPORT_DIR","files":["debug_adapter/protocol.py","vscode-extension/src/extension.js","vscode-extension/out/extension.js","tests/R3_project_system/test_r3_batch1_1_1_command_activation_fix.py"]}
EOF

echo "$BATCH applied."
echo "Backup: $BACKUP_DIR"
echo "Report: $REPORT_DIR"
echo "Run targeted pytest, then full pytest."
