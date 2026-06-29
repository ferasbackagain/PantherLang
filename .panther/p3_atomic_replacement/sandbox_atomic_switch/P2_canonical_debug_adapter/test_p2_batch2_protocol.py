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
