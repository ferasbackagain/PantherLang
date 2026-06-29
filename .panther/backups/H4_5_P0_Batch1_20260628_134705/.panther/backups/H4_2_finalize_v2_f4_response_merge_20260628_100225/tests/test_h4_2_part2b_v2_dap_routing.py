from debug_adapter.dispatcher import RequestDispatcher


def boot_dispatcher_with_launch():
    dispatcher = RequestDispatcher()
    init = dispatcher.dispatch({"seq": 1, "type": "request", "command": "initialize", "arguments": {}})
    assert init["type"] == "response"
    assert init["success"] is True

    config = dispatcher.dispatch({"seq": 2, "type": "request", "command": "configurationDone"})
    assert config["success"] is True

    bps = dispatcher.dispatch({
        "seq": 3,
        "type": "request",
        "command": "setBreakpoints",
        "arguments": {"source": {"path": "examples/hello.pan"}, "breakpoints": [{"line": 1}]},
    })
    assert bps["success"] is True
    assert len(bps["body"]["breakpoints"]) == 1

    launched = dispatcher.dispatch({
        "seq": 4,
        "type": "request",
        "command": "launch",
        "arguments": {"program": "examples/hello.pan", "dryRun": True},
    })
    assert launched["type"] == "event"
    assert launched["event"] == "process"
    assert launched["request_seq"] == 4
    assert launched["body"]["execution"]["status"] == "ready"
    return dispatcher


def test_continue_pause_stop_terminate_disconnect_events():
    dispatcher = boot_dispatcher_with_launch()

    continued = dispatcher.dispatch({"seq": 5, "type": "request", "command": "continue", "arguments": {"threadId": 1}})
    assert continued["type"] == "event"
    assert continued["event"] == "continued"
    assert continued["body"]["status"] == "running"

    paused = dispatcher.dispatch({"seq": 6, "type": "request", "command": "pause", "arguments": {"threadId": 1}})
    assert paused["type"] == "event"
    assert paused["event"] == "stopped"
    assert paused["body"]["reason"] == "pause"
    assert paused["body"]["status"] == "paused"

    resumed = dispatcher.dispatch({"seq": 7, "type": "request", "command": "continue", "arguments": {"threadId": 1}})
    assert resumed["event"] == "continued"
    assert resumed["body"]["status"] == "running"

    stopped = dispatcher.dispatch({"seq": 8, "type": "request", "command": "stop", "arguments": {"threadId": 1}})
    assert stopped["event"] == "stopped"
    assert stopped["body"]["reason"] == "stop"
    assert stopped["body"]["status"] == "stopped"

    terminated = dispatcher.dispatch({"seq": 9, "type": "request", "command": "terminate"})
    assert terminated["event"] == "terminated"

    exited = dispatcher.dispatch({"seq": 10, "type": "request", "command": "disconnect"})
    assert exited["event"] == "exited"


def test_unknown_command_still_returns_clean_error_response():
    dispatcher = RequestDispatcher()
    response = dispatcher.dispatch({"seq": 100, "type": "request", "command": "noSuchCommand"})
    assert response["type"] == "response"
    assert response["success"] is False
    assert "Unsupported command" in response["message"]
