from debug_adapter_rebuilt.request_dispatcher import RequestDispatcher
from debug_adapter_rebuilt.response_dispatcher import ResponseDispatcher
from debug_adapter_rebuilt.execution_dispatcher import ExecutionDispatcher
from debug_adapter_rebuilt.event_bus import EventBus
from debug_adapter_rebuilt.event_dispatcher import EventDispatcher


def test_response_dispatcher_contract():
    r = ResponseDispatcher()
    ok = r.success("initialize", 7, {"x": True})
    assert ok["type"] == "response"
    assert ok["success"] is True
    assert ok["request_seq"] == 7
    assert ok["body"]["x"] is True
    err = r.error("bad", 8, "no")
    assert err["success"] is False
    assert err["message"] == "no"


def test_execution_dispatcher_events():
    bus = EventBus()
    events = EventDispatcher(bus)
    ex = ExecutionDispatcher(events)
    launch = ex.launch("main.pan", request_seq=3)
    assert launch["type"] == "event"
    assert launch["event"] == "process"
    assert launch["request_seq"] == 3
    assert ex.pause(request_seq=4)["event"] == "stopped"
    assert ex.continue_(request_seq=5)["event"] == "continued"
    assert ex.terminate(request_seq=6)["event"] == "terminated"
    assert len(bus) == 4


def test_request_dispatcher_full_core_flow():
    d = RequestDispatcher()
    init = d.dispatch({"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}})
    assert init["success"] is True
    assert init["body"]["panther"]["realDAPFraming"] is True

    config = d.dispatch({"seq": 2, "type": "request", "command": "configurationDone"})
    assert config["success"] is True

    bps = d.dispatch({
        "seq": 3,
        "type": "request",
        "command": "setBreakpoints",
        "arguments": {"source": {"path": "main.pan"}, "breakpoints": [{"line": 2}]},
    })
    assert bps["success"] is True
    assert bps["body"]["breakpoints"][0]["verified"] is True

    launch = d.dispatch({"seq": 4, "type": "request", "command": "launch", "arguments": {"program": "main.pan"}})
    assert launch["type"] == "event"
    assert launch["event"] == "process"
    assert launch["request_seq"] == 4

    cont = d.dispatch({"seq": 5, "type": "request", "command": "continue"})
    assert cont["event"] == "continued"

    pause = d.dispatch({"seq": 6, "type": "request", "command": "pause"})
    assert pause["event"] == "stopped"

    term = d.dispatch({"seq": 7, "type": "request", "command": "terminate"})
    assert term["event"] == "terminated"

    disc = d.dispatch({"seq": 8, "type": "request", "command": "disconnect"})
    assert disc["success"] is True
