from dataclasses import dataclass
import json

class DAPProtocolError(Exception):
    pass

@dataclass
class DAPEncodedMessage:
    content: str

    def __str__(self):
        return self.content

    def encode(self):
        return self.content.encode("utf-8")

@dataclass
class DAPDecodedMessage:
    message: dict

def encode_message(message):
    body = json.dumps(message)
    return f"Content-Length: {len(body)}\r\n\r\n{body}"

def decode_message(data):
    if isinstance(data, bytes):
        data = data.decode("utf-8")
    if isinstance(data, DAPEncodedMessage):
        data = data.content
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

__all__ = [
    "DAPProtocol",
    "DAPProtocolError",
    "DAPEncodedMessage",
    "DAPDecodedMessage",
    "encode_message",
    "decode_message",
    "read_message",
]
