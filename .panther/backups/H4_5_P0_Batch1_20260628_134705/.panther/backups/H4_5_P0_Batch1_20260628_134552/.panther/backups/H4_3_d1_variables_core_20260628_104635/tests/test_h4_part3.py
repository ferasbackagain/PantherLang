from io import StringIO

from debug_adapter.dispatcher import RequestDispatcher
from debug_adapter.protocol import DAPProtocol, DAPProtocolError, encode_message, read_message


def test_dispatcher_routes_initialize_configuration_launch_terminate_disconnect():
    dispatcher = RequestDispatcher()

    initialize = dispatcher.dispatch({
        "seq": 1,
        "type": "request",
        "command": "initialize",
        "arguments": {"adapterID": "panther"},
    })
    assert initialize["success"] is True
    assert initialize["body"]["supportsConfigurationDoneRequest"] is True

    config = dispatcher.dispatch({
        "seq": 2,
        "type": "request",
        "command": "configurationDone",
    })
    assert config["success"] is True

    launch = dispatcher.dispatch({
        "seq": 3,
        "type": "request",
        "command": "launch",
        "arguments": {"program": "main.pan", "args": ["--debug"], "dryRun": True},
    })
    assert launch["type"] == "event"
    assert launch["event"] == "process"
    assert launch["body"]["state"] == "running"
    assert launch["body"]["command"] == ["Panther", "run", "main.pan", "--debug"]

    terminated = dispatcher.dispatch({"seq": 4, "type": "request", "command": "terminate"})
    assert terminated["event"] == "terminated"

    exited = dispatcher.dispatch({"seq": 5, "type": "request", "command": "disconnect"})
    assert exited["event"] == "exited"


def test_dispatcher_rejects_unknown_command():
    dispatcher = RequestDispatcher()
    response = dispatcher.dispatch({"seq": 99, "type": "request", "command": "unknownCommand"})
    assert response["type"] == "response"
    assert response["success"] is False
    assert "Unsupported command" in response["message"]


def test_protocol_keeps_part1_compatibility_with_content_length_framing():
    message = {"seq": 1, "type": "request", "command": "initialize", "arguments": {}}
    encoded = encode_message(message)

    assert encoded.startswith("Content-Length:")
    decoded = read_message(StringIO(encoded))
    assert decoded == message

    encoded_via_class = DAPProtocol.encode(message)
    assert read_message(StringIO(encoded_via_class)) == message


def test_protocol_rejects_invalid_headers():
    try:
        read_message(StringIO("BadHeader\r\n\r\n{}"))
    except DAPProtocolError as exc:
        assert "malformed" in str(exc)
    else:
        raise AssertionError("invalid DAP header was not rejected")
