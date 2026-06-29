import json


class DAPProtocolError(RuntimeError):
    """Raised when a DAP message is malformed or cannot be decoded."""


def _read_header_line(stream):
    line = stream.readline()
    if isinstance(line, bytes):
        line = line.decode("utf-8", errors="replace")
    return line


def read_message(stream):
    """Read one Debug Adapter Protocol message using Content-Length framing."""
    headers = {}

    while True:
        line = _read_header_line(stream)
        if line == "":
            raise DAPProtocolError("unexpected EOF while reading DAP headers")

        line = line.strip()
        if not line:
            break

        if ":" not in line:
            raise DAPProtocolError(f"malformed DAP header: {line}")

        key, value = line.split(":", 1)
        headers[key.strip().lower()] = value.strip()

    if "content-length" not in headers:
        raise DAPProtocolError("missing Content-Length header")

    try:
        content_length = int(headers["content-length"])
    except ValueError as exc:
        raise DAPProtocolError("invalid Content-Length header") from exc

    body = stream.read(content_length)
    if isinstance(body, bytes):
        body = body.decode("utf-8", errors="replace")

    try:
        return json.loads(body)
    except json.JSONDecodeError as exc:
        raise DAPProtocolError("invalid DAP JSON body") from exc


def encode_message(message):
    """Encode a DAP message with Content-Length framing."""
    body = json.dumps(message, separators=(",", ":"))
    return f"Content-Length: {len(body.encode('utf-8'))}\r\n\r\n{body}"


def write_message(stream, message):
    payload = encode_message(message)
    try:
        stream.write(payload)
    except TypeError:
        stream.write(payload.encode("utf-8"))

    if hasattr(stream, "flush"):
        stream.flush()


class DAPProtocol:
    @staticmethod
    def decode_json(data):
        try:
            return json.loads(data)
        except json.JSONDecodeError as exc:
            raise DAPProtocolError("invalid DAP JSON") from exc

    @staticmethod
    def encode_json(message):
        return json.dumps(message, separators=(",", ":"))

    @staticmethod
    def encode(message):
        return encode_message(message)

    @staticmethod
    def read(stream):
        return read_message(stream)

    @staticmethod
    def write(stream, message):
        return write_message(stream, message)
