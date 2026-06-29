from debug_adapter.dispatcher import RequestDispatcher
from debug_adapter.event_dispatcher import EventDispatcher


def test_f5_event_dispatcher_accepts_debug_server_process_signature():
    events = EventDispatcher()
    message = events.process(
        name="examples/hello.pan",
        pid=777,
        command=["Panther", "run", "examples/hello.pan"],
        state="running",
        execution={"threadId": 1},
    )

    assert message["type"] == "event"
    assert message["event"] == "process"
    assert message["body"]["name"] == "examples/hello.pan"
    assert message["body"]["systemProcessId"] == 777
    assert message["body"]["command"] == ["Panther", "run", "examples/hello.pan"]
    assert message["body"]["state"] == "running"
    assert message["body"]["execution"]["threadId"] == 1


def test_f5_dispatcher_launch_still_returns_event():
    dispatcher = RequestDispatcher()

    assert dispatcher.dispatch({"seq": 1, "type": "request", "command": "initialize", "arguments": {}})["success"] is True
    assert dispatcher.dispatch({"seq": 2, "type": "request", "command": "configurationDone"})["success"] is True

    launched = dispatcher.dispatch({
        "seq": 3,
        "type": "request",
        "command": "launch",
        "arguments": {"program": "examples/hello.pan", "dryRun": True},
    })

    assert launched["type"] == "event"
    assert launched["event"] == "process"
