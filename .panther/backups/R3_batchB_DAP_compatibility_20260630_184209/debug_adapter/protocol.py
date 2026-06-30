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
