from io import StringIO

from debug_adapter.dispatcher import RequestDispatcher
from debug_adapter.protocol import encode_message, read_message


def test_dap_set_breakpoints_response_shape(tmp_path):
    source = tmp_path / "main.pan"
    source.write_text("// comment\n\nlet x = 1\nprint(x)\n", encoding="utf-8")
    dispatcher = RequestDispatcher()

    assert dispatcher.dispatch({"seq": 1, "type": "request", "command": "initialize", "arguments": {}})["success"]

    request = {
        "seq": 2,
        "type": "request",
        "command": "setBreakpoints",
        "arguments": {
            "source": {"path": str(source)},
            "breakpoints": [{"line": 1}, {"line": 4, "condition": "x == 1"}],
        },
    }
    framed = encode_message(request)
    parsed = read_message(StringIO(framed))
    response = dispatcher.dispatch(parsed)

    assert response["type"] == "response"
    assert response["success"] is True
    assert response["command"] == "setBreakpoints"
    assert len(response["body"]["breakpoints"]) == 2
    assert response["body"]["breakpoints"][0]["verified"] is True
    assert response["body"]["breakpoints"][0]["line"] == 3
    assert response["body"]["breakpoints"][1]["line"] == 4


def test_end_to_end_with_breakpoints_then_launch(tmp_path):
    source = tmp_path / "demo.pan"
    source.write_text("let a = 1\nlet b = 2\n", encoding="utf-8")
    dispatcher = RequestDispatcher()

    assert dispatcher.dispatch({"seq": 1, "type": "request", "command": "initialize", "arguments": {}})["success"]
    bp_response = dispatcher.dispatch({
        "seq": 2,
        "type": "request",
        "command": "setBreakpoints",
        "arguments": {"source": {"path": str(source)}, "breakpoints": [{"line": 2}]},
    })
    assert bp_response["body"]["breakpoints"][0]["verified"] is True

    assert dispatcher.dispatch({"seq": 3, "type": "request", "command": "configurationDone"})["success"]
    launch = dispatcher.dispatch({
        "seq": 4,
        "type": "request",
        "command": "launch",
        "arguments": {"program": str(source), "dryRun": True},
    })
    assert launch["event"] == "process"
    assert launch["body"]["state"] == "running"
    assert dispatcher.dispatch({"seq": 5, "type": "request", "command": "terminate"})["event"] == "terminated"
    assert dispatcher.dispatch({"seq": 6, "type": "request", "command": "disconnect"})["event"] == "exited"
