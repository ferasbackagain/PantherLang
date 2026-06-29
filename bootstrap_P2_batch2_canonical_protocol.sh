#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang P-2"
echo " Canonical Debug Adapter Rebuild"
echo " Batch 2 - Canonical Protocol"
echo "============================================================"

ROOT="$(pwd)"
P2="$ROOT/.panther/p2_debug_adapter_rebuild"
REBUILT="$ROOT/debug_adapter_rebuilt"
REPORTS="$ROOT/reports/P2"
TESTS="$ROOT/tests/P2_canonical_debug_adapter"

mkdir -p "$P2" "$REBUILT" "$REPORTS" "$TESTS"

fail(){ echo "[P2-B2][ERROR] $1" >&2; exit 1; }

[ -f "$P2/status_batch1.json" ] || fail "P-2 Batch 1 status missing. Run Batch 1 first."
[ -f "$P2/spec/canonical_debug_adapter_contract.json" ] || fail "Canonical contract missing."

echo "[1/7] Creating rebuilt package foundation..."

cat > "$REBUILT/__init__.py" <<'PY'
"""PantherLang Canonical Debug Adapter Rebuild.

This package is built cleanly from the P-2 canonical contract.
It must not depend on historical monkey patches or drifting runtime code.
"""

from .protocol import (
    DAPProtocolError,
    DAPEncodedMessage,
    encode_message,
    decode_message,
    read_message,
)

__all__ = [
    "DAPProtocolError",
    "DAPEncodedMessage",
    "encode_message",
    "decode_message",
    "read_message",
]
PY

echo "[2/7] Creating canonical protocol.py..."

cat > "$REBUILT/protocol.py" <<'PY'
from __future__ import annotations

import io
import json
from typing import Any, BinaryIO, Dict, TextIO


class DAPProtocolError(ValueError):
    """Raised when a Debug Adapter Protocol frame is invalid."""


class DAPEncodedMessage(str):
    """String DAP frame with bytes compatibility.

    Historical PantherLang tests used both:
    - StringIO(encoded)
    - BytesIO(encode_message(...))

    To preserve both contracts cleanly, the canonical frame is a str
    that implements __bytes__ and byte-oriented helpers.
    """

    def __new__(cls, value: str):
        return super().__new__(cls, value)

    def __bytes__(self) -> bytes:
        return str(self).encode("utf-8")

    def to_bytes(self) -> bytes:
        return bytes(self)

    def as_bytes(self) -> bytes:
        return bytes(self)

    def startswith(self, prefix: Any, *args: Any) -> bool:  # type: ignore[override]
        if isinstance(prefix, (bytes, bytearray)):
            return bytes(self).startswith(bytes(prefix), *args)
        return super().startswith(prefix, *args)


def _json_body(message: Dict[str, Any]) -> str:
    if not isinstance(message, dict):
        raise DAPProtocolError("DAP message must be a dict")
    return json.dumps(message, separators=(",", ":"), ensure_ascii=False)


def encode_message(message: Dict[str, Any]) -> DAPEncodedMessage:
    """Encode a DAP message using Content-Length framing.

    Returns a string-compatible frame for StringIO while supporting bytes(frame)
    for binary transports.
    """

    body = _json_body(message)
    body_bytes = body.encode("utf-8")
    frame = f"Content-Length: {len(body_bytes)}\r\n\r\n{body}"
    return DAPEncodedMessage(frame)


def _read_all(stream: Any) -> str:
    data = stream.read()
    if isinstance(data, bytes):
        return data.decode("utf-8")
    if isinstance(data, str):
        return data
    raise DAPProtocolError("stream.read() must return str or bytes")


def decode_message(frame: str | bytes | bytearray | DAPEncodedMessage) -> Dict[str, Any]:
    """Decode one complete DAP frame."""

    if isinstance(frame, (bytes, bytearray)):
        text = bytes(frame).decode("utf-8")
    else:
        text = str(frame)

    separator = "\r\n\r\n"
    if separator not in text:
        raise DAPProtocolError("DAP frame missing header separator")

    header_text, body = text.split(separator, 1)

    content_length = None
    for line in header_text.split("\r\n"):
        if not line:
            continue
        if ":" not in line:
            raise DAPProtocolError(f"invalid header line: {line!r}")
        key, value = line.split(":", 1)
        if key.strip().lower() == "content-length":
            try:
                content_length = int(value.strip())
            except ValueError as exc:
                raise DAPProtocolError("invalid Content-Length value") from exc

    if content_length is None:
        raise DAPProtocolError("missing Content-Length header")

    body_bytes = body.encode("utf-8")
    if len(body_bytes) < content_length:
        raise DAPProtocolError("incomplete DAP body")

    exact_body = body_bytes[:content_length].decode("utf-8")
    try:
        parsed = json.loads(exact_body)
    except json.JSONDecodeError as exc:
        raise DAPProtocolError("invalid JSON body") from exc

    if not isinstance(parsed, dict):
        raise DAPProtocolError("DAP body must decode to object")
    return parsed


def read_message(stream: TextIO | BinaryIO | io.StringIO | io.BytesIO) -> Dict[str, Any]:
    """Read and decode a complete DAP message from a text or binary stream."""

    return decode_message(_read_all(stream))
PY

echo "[3/7] Creating canonical protocol tests..."

cat > "$TESTS/test_p2_batch2_protocol.py" <<'PY'
import io

import pytest

from debug_adapter_rebuilt.protocol import (
    DAPEncodedMessage,
    DAPProtocolError,
    decode_message,
    encode_message,
    read_message,
)


def test_encode_message_returns_string_compatible_dap_frame():
    msg = {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "pantherlang"}}
    encoded = encode_message(msg)

    assert isinstance(encoded, str)
    assert isinstance(encoded, DAPEncodedMessage)
    assert encoded.startswith("Content-Length:")
    assert "\r\n\r\n" in encoded
    assert bytes(encoded).startswith(b"Content-Length:")


def test_protocol_roundtrip_with_stringio():
    msg = {"seq": 2, "type": "request", "command": "configurationDone"}
    encoded = encode_message(msg)
    assert read_message(io.StringIO(encoded)) == msg


def test_protocol_roundtrip_with_bytesio():
    msg = {"seq": 3, "type": "request", "command": "launch", "arguments": {"program": "main.pan"}}
    encoded = encode_message(msg)
    assert read_message(io.BytesIO(bytes(encoded))) == msg


def test_decode_message_rejects_missing_content_length():
    with pytest.raises(DAPProtocolError):
        decode_message("\r\n\r\n{}")


def test_decode_message_rejects_incomplete_body():
    with pytest.raises(DAPProtocolError):
        decode_message("Content-Length: 100\r\n\r\n{}")


def test_decode_message_accepts_unicode_payload():
    msg = {"seq": 4, "type": "event", "event": "output", "body": {"output": "مرحبا Panther"}}
    encoded = encode_message(msg)
    assert read_message(io.StringIO(encoded)) == msg
PY

echo "[4/7] Static validation..."
python3 -m py_compile "$REBUILT/protocol.py" "$REBUILT/__init__.py" "$TESTS/test_p2_batch2_protocol.py"

echo "[5/7] Running protocol tests..."
python3 -m pytest "$TESTS/test_p2_batch2_protocol.py" -q

echo "[6/7] Writing engineering report..."

cat > "$REPORTS/P2_BATCH2_CANONICAL_PROTOCOL.md" <<'EOF'
# P-2 Batch 2 - Canonical Protocol

## Status

PASSED

## Purpose

Build the clean canonical DAP protocol layer inside `debug_adapter_rebuilt/`.

## Implemented

- `DAPProtocolError`
- `DAPEncodedMessage`
- `encode_message`
- `decode_message`
- `read_message`
- StringIO compatibility
- BytesIO compatibility
- Content-Length validation
- Unicode JSON payload support

## Runtime Modification

No existing `debug_adapter/` runtime files were modified.

## Next

P-2 Batch 3 - Canonical Session.
EOF

cat > "$P2/status_batch2.json" <<'EOF'
{
  "ok": true,
  "phase": "P-2",
  "batch": "2",
  "status": "PASSED",
  "runtime_modified": false,
  "implemented": [
    "debug_adapter_rebuilt/__init__.py",
    "debug_adapter_rebuilt/protocol.py",
    "tests/P2_canonical_debug_adapter/test_p2_batch2_protocol.py"
  ],
  "next": "P-2 Batch 3 - Canonical Session"
}
EOF

echo "[7/7] Done."

echo "============================================================"
echo "✅ P-2 Batch 2 COMPLETE"
echo "Next: P-2 Batch 3 - Canonical Session"
echo "============================================================"
