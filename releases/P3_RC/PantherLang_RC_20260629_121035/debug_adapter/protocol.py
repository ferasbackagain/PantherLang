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


# P-3 Batch 7.5 compatibility helper. The canonical encode_message return remains
# string-compatible for P2/P3. H4 byte-stream callers should use this explicit helper.
def encode_message_bytes(message):
    return bytes(encode_message(message))
