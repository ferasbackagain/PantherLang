from io import StringIO, BytesIO

from debug_adapter_bridge.protocol import encode_message, read_message
from debug_adapter_bridge.session import DebugSession
from debug_adapter_bridge.event_bus import EventBus
from debug_adapter_bridge.event_dispatcher import EventDispatcher
from debug_adapter_bridge.request_dispatcher import RequestDispatcher
from debug_adapter_bridge.server import DebugServer
from debug_adapter_bridge.variable_store import VariableStore
from debug_adapter_bridge.evaluate import EvaluateEngine


def test_bridge_protocol_roundtrip_string_and_bytes():
    msg = {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}}
    framed = encode_message(msg)
    assert read_message(StringIO(framed)) == msg
    assert read_message(BytesIO(bytes(framed))) == msg


def test_bridge_session_contract():
    s = DebugSession()
    s.apply_initialize_arguments({"adapterID": "panther"})
    assert s.initialized is True
    assert s.capabilities()["panther"]["realDAPFraming"] is True
    s.configuration_done()
    assert s.state == "configured"


def test_bridge_event_dispatcher_contract():
    bus = EventBus()
    dispatcher = EventDispatcher(bus)
    event = dispatcher.process(
        name="main.pan",
        pid=123,
        command=["Panther", "run", "main.pan"],
        execution={"status": "ready"},
        request_seq=7,
    )
    assert event["type"] == "event"
    assert event["event"] == "process"
    assert event["request_seq"] == 7
    assert len(bus) == 1
    assert bus.drain()[0] == event


def test_bridge_request_dispatcher_core_flow():
    d = RequestDispatcher()
    assert d.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
    assert d.dispatch({"seq": 2, "command": "configurationDone"})["success"] is True
    launch = d.dispatch({"seq": 3, "command": "launch", "arguments": {"program": "hello.pan"}})
    assert launch["type"] == "event"
    assert launch["event"] == "process"
    assert launch["request_seq"] == 3
    assert d.dispatch({"seq": 4, "command": "continue"})["event"] == "continued"
    assert d.dispatch({"seq": 5, "command": "pause"})["event"] == "stopped"
    assert d.dispatch({"seq": 6, "command": "terminate"})["event"] == "terminated"


def test_bridge_server_and_data_model():
    server = DebugServer()
    assert server.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
    assert server.dispatch({"seq": 2, "command": "launch", "arguments": {"program": "x.pan"}})["event"] == "process"

    store = VariableStore()
    store.set("x", 5)
    assert store.get("x").value == "5"

    evaluator = EvaluateEngine({"x": 5})
    assert evaluator.evaluate("x + 1").result == "6"
