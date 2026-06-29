from debug_adapter.dispatcher import RequestDispatcher
from debug_adapter.execution_dispatcher import ExecutionDispatcher
from debug_adapter.execution_merge import ExecutionMergeEngine


def test_f6_execution_state_contract_direct_engine():
    engine = ExecutionMergeEngine()

    configured = engine.configuration_done()
    assert configured["configured"] is True
    assert configured["state"] == "configured"

    bps = engine.set_breakpoints([{"line": 3}])
    assert len(bps["breakpoints"]) == 1
    assert bps["breakpoints"][0]["line"] == 3

    launched = engine.launch("examples/hello.pan", dry_run=True)
    assert launched["state"] == "running"
    assert launched["execution"]["launched"] is True
    assert launched["execution"]["running"] is True

    paused = engine.pause()
    assert paused["state"] == "paused"
    assert paused["execution"]["paused"] is True

    continued = engine.continue_execution()
    assert continued["state"] == "running"
    assert continued["execution"]["running"] is True

    stopped = engine.stop()
    assert stopped["state"] == "stopped"
    assert stopped["execution"]["stopped"] is True

    terminated = engine.terminate()
    assert terminated["state"] == "terminated"
    assert terminated["execution"]["terminated"] is True

    assert engine.assert_execution_contract(engine.current()) is True


def test_f6_execution_dispatcher_facade():
    dispatcher = ExecutionDispatcher()

    dispatcher.configuration_done()
    dispatcher.set_breakpoints([{"line": 1}, {"line": 5}])
    launch = dispatcher.launch("examples/hello.pan", dry_run=True)

    assert launch["threadId"] == 1
    assert launch["execution"]["program"] == "examples/hello.pan"
    assert launch["execution"]["launched"] is True

    pause = dispatcher.pause()
    assert pause["execution"]["paused"] is True

    cont = dispatcher.continue_execution()
    assert cont["execution"]["running"] is True

    term = dispatcher.terminate()
    assert term["execution"]["terminated"] is True


def test_f6_existing_dap_routing_still_preserved():
    dispatcher = RequestDispatcher()

    init = dispatcher.dispatch({"seq": 1, "type": "request", "command": "initialize", "arguments": {}})
    assert init["type"] == "response"
    assert init["success"] is True

    config = dispatcher.dispatch({"seq": 2, "type": "request", "command": "configurationDone"})
    assert config["type"] == "response"
    assert config["success"] is True

    bps = dispatcher.dispatch({
        "seq": 3,
        "type": "request",
        "command": "setBreakpoints",
        "arguments": {
            "source": {"path": "examples/hello.pan"},
            "breakpoints": [{"line": 1}],
        },
    })
    assert bps["type"] == "response"
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

    cont = dispatcher.dispatch({"seq": 5, "type": "request", "command": "continue"})
    assert cont["type"] == "event"
    assert cont["event"] == "continued"

    pause = dispatcher.dispatch({"seq": 6, "type": "request", "command": "pause"})
    assert pause["type"] == "event"
    assert pause["event"] == "stopped"

    stop = dispatcher.dispatch({"seq": 7, "type": "request", "command": "stop"})
    assert stop["type"] == "event"
    assert stop["event"] == "stopped"

    terminate = dispatcher.dispatch({"seq": 8, "type": "request", "command": "terminate"})
    assert terminate["type"] == "event"
    assert terminate["event"] == "terminated"

    disconnect = dispatcher.dispatch({"seq": 9, "type": "request", "command": "disconnect"})
    assert disconnect["type"] in {"event", "response"}
