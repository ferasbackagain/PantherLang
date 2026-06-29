from __future__ import annotations

import io
import json
from debug_adapter.protocol import encode_message, read_message
from debug_adapter.session import DebugSession


def test_dap_protocol_roundtrip():
    msg = {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "pantherlang"}}
    stream = io.BytesIO(encode_message(msg))
    assert read_message(stream) == msg


def test_session_capabilities_are_dap_ready():
    s = DebugSession()
    s.apply_initialize_arguments({"clientID": "pytest", "adapterID": "pantherlang"})
    caps = s.capabilities()
    assert s.initialized is True
    assert caps["supportsConfigurationDoneRequest"] is True
    assert caps["panther"]["realDAPFraming"] is True
