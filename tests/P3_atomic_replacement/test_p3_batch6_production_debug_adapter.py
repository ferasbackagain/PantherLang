from io import StringIO, BytesIO

from debug_adapter.protocol import encode_message, read_message
from debug_adapter.server import DebugServer
from debug_adapter.request_dispatcher import RequestDispatcher
from debug_adapter.variable_store import VariableStore
from debug_adapter.evaluate import EvaluateEngine


def test_production_debug_adapter_protocol_and_server():
    msg = {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}}
    framed = encode_message(msg)
    assert read_message(StringIO(framed)) == msg
    assert read_message(BytesIO(bytes(framed))) == msg

    server = DebugServer()
    assert server.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
    launch = server.dispatch({"seq": 2, "command": "launch", "arguments": {"program": "main.pan"}})
    assert launch["type"] == "event"
    assert launch["event"] == "process"


def test_production_dispatcher_and_data_model():
    d = RequestDispatcher()
    assert d.dispatch({"seq": 1, "command": "initialize", "arguments": {}})["success"] is True
    assert d.dispatch({"seq": 2, "command": "configurationDone"})["success"] is True
    assert d.dispatch({"seq": 3, "command": "launch", "arguments": {"program": "x.pan"}})["event"] == "process"

    store = VariableStore()
    store.set("x", 7)
    assert store.get("x").value == "7"
    assert EvaluateEngine({"x": 7}).evaluate("x + 1").result == "8"
