from debug_adapter.dispatcher import RequestDispatcher


def test_f7_professional_dap_flow_regression():
    dispatcher = RequestDispatcher()

    init = dispatcher.dispatch({
        "seq": 1,
        "type": "request",
        "command": "initialize",
        "arguments": {},
    })
    assert init["type"] == "response"
    assert init["success"] is True
    assert init["command"] == "initialize"
    assert init["request_seq"] == 1

    config = dispatcher.dispatch({
        "seq": 2,
        "type": "request",
        "command": "configurationDone",
    })
    assert config["type"] == "response"
    assert config["success"] is True
    assert config["command"] == "configurationDone"
    assert config["request_seq"] == 2

    bps = dispatcher.dispatch({
        "seq": 3,
        "type": "request",
        "command": "setBreakpoints",
        "arguments": {
            "source": {"path": "examples/hello.pan"},
            "breakpoints": [{"line": 1}, {"line": 3}],
        },
    })
    assert bps["type"] == "response"
    assert bps["success"] is True
    assert bps["command"] == "setBreakpoints"
    assert bps["request_seq"] == 3
    assert len(bps["body"]["breakpoints"]) == 2

    launch = dispatcher.dispatch({
        "seq": 4,
        "type": "request",
        "command": "launch",
        "arguments": {"program": "examples/hello.pan", "dryRun": True},
    })
    assert launch["type"] == "event"
    assert launch["event"] == "process"
    assert launch["request_seq"] == 4
    assert launch["sourceCommand"] == "launch"

    cont1 = dispatcher.dispatch({
        "seq": 5,
        "type": "request",
        "command": "continue",
    })
    assert cont1["type"] == "event"
    assert cont1["event"] == "continued"
    assert cont1["request_seq"] == 5
    assert cont1["sourceCommand"] == "continue"

    pause = dispatcher.dispatch({
        "seq": 6,
        "type": "request",
        "command": "pause",
    })
    assert pause["type"] == "event"
    assert pause["event"] == "stopped"
    assert pause["request_seq"] == 6
    assert pause["sourceCommand"] == "pause"

    cont2 = dispatcher.dispatch({
        "seq": 7,
        "type": "request",
        "command": "continue",
    })
    assert cont2["type"] == "event"
    assert cont2["event"] == "continued"
    assert cont2["request_seq"] == 7
    assert cont2["sourceCommand"] == "continue"

    stop = dispatcher.dispatch({
        "seq": 8,
        "type": "request",
        "command": "stop",
    })
    assert stop["type"] == "event"
    assert stop["event"] == "stopped"
    assert stop["request_seq"] == 8
    assert stop["sourceCommand"] == "stop"

    terminate = dispatcher.dispatch({
        "seq": 9,
        "type": "request",
        "command": "terminate",
    })
    assert terminate["type"] == "event"
    assert terminate["event"] == "terminated"
    assert terminate["request_seq"] == 9
    assert terminate["sourceCommand"] == "terminate"

    disconnect = dispatcher.dispatch({
        "seq": 10,
        "type": "request",
        "command": "disconnect",
    })
    assert disconnect["type"] in {"event", "response"}
    if disconnect["type"] == "event":
        assert disconnect["request_seq"] == 10
        assert disconnect["sourceCommand"] == "disconnect"
    else:
        assert disconnect["request_seq"] == 10
        assert disconnect["command"] == "disconnect"


def test_f7_unsupported_command_still_returns_clean_error_response():
    dispatcher = RequestDispatcher()

    bad = dispatcher.dispatch({
        "seq": 99,
        "type": "request",
        "command": "notARealCommand",
    })

    assert bad["type"] == "response"
    assert bad["success"] is False
    assert bad["request_seq"] == 99
    assert bad["command"] == "notARealCommand"
    assert "Unsupported command" in bad["message"]
