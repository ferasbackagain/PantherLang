from debug_adapter.dispatcher import RequestDispatcher
from debug_adapter.response_dispatcher import ResponseDispatcher


def test_f5_response_dispatcher_preserves_event_and_adds_request_seq():
    dispatcher = ResponseDispatcher()
    event = dispatcher.normalize(
        {"type": "event", "event": "process", "body": {"name": "demo.pan"}},
        request_seq=44,
        command="launch",
    )

    assert event["type"] == "event"
    assert event["event"] == "process"
    assert event["request_seq"] == 44
    assert event["sourceCommand"] == "launch"


def test_f5_launch_event_has_request_seq():
    dispatcher = RequestDispatcher()

    dispatcher.dispatch({"seq": 1, "type": "request", "command": "initialize", "arguments": {}})
    dispatcher.dispatch({"seq": 2, "type": "request", "command": "configurationDone"})

    launched = dispatcher.dispatch({
        "seq": 4,
        "type": "request",
        "command": "launch",
        "arguments": {"program": "examples/hello.pan", "dryRun": True},
    })

    assert launched["type"] == "event"
    assert launched["event"] == "process"
    assert launched["request_seq"] == 4
    assert launched["sourceCommand"] == "launch"
