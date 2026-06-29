from io import StringIO, BytesIO

from debug_adapter_rebuilt.protocol import encode_message, read_message
from debug_adapter_rebuilt.server import DebugServer
from debug_adapter_rebuilt.request_dispatcher import RequestDispatcher
from debug_adapter_rebuilt.event_bus import EventBus
from debug_adapter_rebuilt.event_dispatcher import EventDispatcher
from debug_adapter_rebuilt.execution_dispatcher import ExecutionDispatcher
from debug_adapter_rebuilt.variable_store import VariableStore
from debug_adapter_rebuilt.stack_frames import StackFrameStore
from debug_adapter_rebuilt.threads import ThreadStore
from debug_adapter_rebuilt.scopes import ScopeStore
from debug_adapter_rebuilt.evaluate import EvaluateEngine


def test_protocol_dispatcher_end_to_end_flow_stringio_and_bytesio():
    dispatcher = RequestDispatcher()
    sequence = [
        {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}},
        {"seq": 2, "type": "request", "command": "configurationDone"},
        {"seq": 3, "type": "request", "command": "setBreakpoints", "arguments": {"source": {"path": "hello.pan"}, "breakpoints": [{"line": 1}]}},
        {"seq": 4, "type": "request", "command": "launch", "arguments": {"program": "hello.pan", "dryRun": True}},
        {"seq": 5, "type": "request", "command": "continue"},
        {"seq": 6, "type": "request", "command": "pause"},
        {"seq": 7, "type": "request", "command": "terminate"},
        {"seq": 8, "type": "request", "command": "disconnect"},
    ]

    responses = []
    for req in sequence:
        framed = encode_message(req)
        assert read_message(StringIO(framed)) == req
        assert read_message(BytesIO(bytes(framed))) == req
        responses.append(dispatcher.dispatch(req))

    assert responses[0]["success"] is True
    assert responses[0]["body"]["panther"]["realDAPFraming"] is True
    assert responses[1]["success"] is True
    assert responses[2]["body"]["breakpoints"][0]["verified"] is True
    assert responses[3]["type"] == "event" and responses[3]["event"] == "process"
    assert responses[4]["event"] == "continued"
    assert responses[5]["event"] == "stopped"
    assert responses[6]["event"] == "terminated"
    assert responses[7]["success"] is True


def test_server_integration_flow_and_event_bus():
    server = DebugServer()
    assert server.dispatch({"seq": 1, "command": "initialize", "arguments": {"adapterID": "panther"}})["success"] is True
    assert server.dispatch({"seq": 2, "command": "configurationDone"})["success"] is True
    launch = server.dispatch({"seq": 3, "command": "launch", "arguments": {"program": "main.pan"}})
    assert launch["event"] == "process"
    assert launch["body"]["name"] == "main.pan"
    assert len(server.bus) == 1
    assert server.bus.drain()[0] == launch


def test_execution_and_data_model_integration():
    bus = EventBus()
    events = EventDispatcher(bus)
    execution = ExecutionDispatcher(events)
    event = execution.launch("program.pan", request_seq=10)
    assert event["request_seq"] == 10
    assert event["body"]["execution"]["status"] == "running"

    variables = VariableStore()
    variables.set("x", 10)
    variables.set("obj", {"a": 1})

    frames = StackFrameStore()
    frame = frames.push("main", line=12, source_path="program.pan")

    threads = ThreadStore()
    scopes = ScopeStore()
    scope = scopes.add("Locals", variablesReference=variables.get("obj").variablesReference)

    evaluator = EvaluateEngine({"x": 10, "y": 5})
    assert evaluator.evaluate("x + y").result == "15"
    assert frame.line == 12
    assert threads.main().id == 1
    assert scope.name == "Locals"
