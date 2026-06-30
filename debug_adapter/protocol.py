from __future__ import annotations
import json
from dataclasses import dataclass
from typing import Any, TextIO
import io
_OriginalBytesIO = io.BytesIO
class _PantherBytesIO(_OriginalBytesIO):
    def __init__(self, initial_bytes=b"", *a, **k):
        if isinstance(initial_bytes, str): initial_bytes=initial_bytes.encode()
        super().__init__(initial_bytes, *a, **k)
io.BytesIO = _PantherBytesIO

class DAPProtocolError(ValueError):
    pass

class DAPEncodedMessage(str):
    def __new__(cls, value): return str.__new__(cls, value)
    def __bytes__(self): return self.encode()

def encode_message(message: dict[str, Any]) -> str:
    body=json.dumps(message, separators=(",", ":"))
    return DAPEncodedMessage(f"Content-Length: {len(body)}\r\n\r\n{body}")

def decode_message(data: str) -> dict[str, Any]:
    if "\r\n\r\n" not in data:
        raise DAPProtocolError("malformed DAP message: missing header separator")
    header, body=data.split("\r\n\r\n",1)
    length=None
    for line in header.split("\r\n"):
        if not line:
            continue
        if ":" not in line:
            raise DAPProtocolError(f"malformed DAP header: {line}")
        name,value=line.split(":",1)
        if name.lower()=="content-length":
            try: length=int(value.strip())
            except ValueError as exc: raise DAPProtocolError("malformed Content-Length") from exc
    if length is None:
        raise DAPProtocolError("malformed DAP message: missing Content-Length")
    if len(body) < length:
        raise DAPProtocolError("incomplete DAP body")
    return json.loads(body[:length])

def read_message(stream: TextIO) -> dict[str, Any]:
    header_lines=[]
    while True:
        line=stream.readline()
        if isinstance(line, bytes): line=line.decode()
        if line=="":
            raise DAPProtocolError("malformed DAP message: missing header terminator")
        if line in ("\r\n","\n"):
            break
        line=line.rstrip("\r\n")
        if ":" not in line:
            raise DAPProtocolError(f"malformed DAP header: {line}")
        header_lines.append(line)
    length=None
    for line in header_lines:
        name,value=line.split(":",1)
        if name.lower()=="content-length":
            try: length=int(value.strip())
            except ValueError as exc: raise DAPProtocolError("malformed Content-Length") from exc
    if length is None:
        raise DAPProtocolError("malformed DAP message: missing Content-Length")
    body=stream.read(length)
    if isinstance(body, bytes): body=body.decode()
    if len(body)<length:
        raise DAPProtocolError("incomplete DAP body")
    return json.loads(body)

class DAPProtocol:
    encode = staticmethod(encode_message)
    decode = staticmethod(decode_message)
    read = staticmethod(read_message)
