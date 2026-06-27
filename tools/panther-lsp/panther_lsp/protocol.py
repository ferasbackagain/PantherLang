from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any, Dict, Iterable, Optional


@dataclass
class JsonRpcMessage:
    """Minimal JSON-RPC 2.0 message wrapper used by the Panther LSP."""

    method: Optional[str]
    params: Dict[str, Any]
    id: Optional[Any] = None

    @staticmethod
    def parse(payload: str) -> "JsonRpcMessage":
        data = json.loads(payload)
        if data.get("jsonrpc") != "2.0":
            raise ValueError("Invalid JSON-RPC version")
        return JsonRpcMessage(method=data.get("method"), params=data.get("params") or {}, id=data.get("id"))


def make_response(message_id: Any, result: Any) -> Dict[str, Any]:
    return {"jsonrpc": "2.0", "id": message_id, "result": result}


def make_error(message_id: Any, code: int, message: str) -> Dict[str, Any]:
    return {"jsonrpc": "2.0", "id": message_id, "error": {"code": code, "message": message}}


def encode_lsp_payload(message: Dict[str, Any]) -> bytes:
    body = json.dumps(message, separators=(",", ":")).encode("utf-8")
    header = f"Content-Length: {len(body)}\r\n\r\n".encode("ascii")
    return header + body


def decode_lsp_stream(chunks: Iterable[bytes]) -> Iterable[Dict[str, Any]]:
    buffer = b""
    for chunk in chunks:
        buffer += chunk
        while True:
            marker = buffer.find(b"\r\n\r\n")
            if marker < 0:
                break
            header = buffer[:marker].decode("ascii", errors="replace")
            length = None
            for line in header.split("\r\n"):
                if line.lower().startswith("content-length:"):
                    length = int(line.split(":", 1)[1].strip())
                    break
            if length is None:
                raise ValueError("Missing Content-Length header")
            start = marker + 4
            end = start + length
            if len(buffer) < end:
                break
            body = buffer[start:end]
            buffer = buffer[end:]
            yield json.loads(body.decode("utf-8"))


def make_notification(method, params=None):
    """Create a JSON-RPC 2.0 notification message.

    Notifications do not include an "id" field.
    """
    message = {
        "jsonrpc": "2.0",
        "method": method,
    }
    if params is not None:
        message["params"] = params
    return message


def parse_message(raw):
    """Parse a JSON-RPC/LSP message from JSON text, bytes, or dict."""
    import json

    if isinstance(raw, dict):
        return raw

    if isinstance(raw, bytes):
        raw = raw.decode("utf-8")

    if isinstance(raw, str):
        raw = raw.strip()

        # Support full LSP framed messages:
        # Content-Length: 123\r\n\r\n{...}
        if raw.lower().startswith("content-length:"):
            _, _, body = raw.partition("\r\n\r\n")
            if not body:
                _, _, body = raw.partition("\n\n")
            raw = body.strip()

        return json.loads(raw)

    raise TypeError("Unsupported message type for parse_message")
