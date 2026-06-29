from io import StringIO

from debug_adapter.dispatcher import RequestDispatcher
from debug_adapter.protocol import encode_message, read_message


def dispatch_framed(dispatcher, request):
    framed = encode_message(request)
    parsed = read_message(StringIO(framed))
    assert parsed == request
    return dispatcher.dispatch(parsed)


def test_full_dap_event_routing_end_to_end():
    dispatcher = RequestDispatcher()

    assert dispatch_framed(dispatcher, {
        "seq": 1,
        "type": "request",
        "command": "initialize",
        "arguments": {"adapterID": "panther"},
    })["success"] is True

    assert dispatch_framed(dispatcher, {
        "seq": 2,
        "type": "request",
        "command": "configurationDone",
    })["success"] is True

    breakpoints = dispatch_framed(dispatcher, {
        "seq": 3,
        "type": "request",
        "command": "setBreakpoints",
        "arguments": {
            "source": {"path": "examples/hello.pan"},
            "breakpoints": [{"line": 1}, {"line": 2}],
        },
    })
    assert breakpoints["success"] is True
    assert len(breakpoints["body"]["breakpoints"]) == 2

    launched = dispatch_framed(dispatcher, {
        "seq": 4,
        "type": "request",
        "command": "launch",
        "arguments": {"program": "examples/hello.pan", "dryRun": True},
    })
    assert launched["type"] == "event"
    assert launched["event"] == "process"
    assert launched["body"]["execution"]["status"] == "ready"

    continued = dispatch_framed(dispatcher, {
        "seq": 5,
        "type": "request",
        "command": "continue",
        "arguments": {"threadId": 1},
    })
    assert continued["event"] == "continued"
    assert continued["body"]["status"] == "running"

    paused = dispatch_framed(dispatcher, {
        "seq": 6,
        "type": "request",
        "command": "pause",
        "arguments": {"threadId": 1},
    })
    assert paused["event"] == "stopped"
    assert paused["body"]["reason"] == "pause"
    assert paused["body"]["status"] == "paused"

    resumed = dispatch_framed(dispatcher, {
        "seq": 7,
        "type": "request",
        "command": "continue",
        "arguments": {"threadId": 1},
    })
    assert resumed["event"] == "continued"
    assert resumed["body"]["status"] == "running"

    stopped = dispatch_framed(dispatcher, {
        "seq": 8,
        "type": "request",
        "command": "stop",
        "arguments": {"threadId": 1},
    })
    assert stopped["event"] == "stopped"
    assert stopped["body"]["status"] == "stopped"

    terminated = dispatch_framed(dispatcher, {"seq": 9, "type": "request", "command": "terminate"})
    assert terminated["event"] == "terminated"

    exited = dispatch_framed(dispatcher, {"seq": 10, "type": "request", "command": "disconnect"})
    assert exited["event"] == "exited"
