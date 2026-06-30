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
