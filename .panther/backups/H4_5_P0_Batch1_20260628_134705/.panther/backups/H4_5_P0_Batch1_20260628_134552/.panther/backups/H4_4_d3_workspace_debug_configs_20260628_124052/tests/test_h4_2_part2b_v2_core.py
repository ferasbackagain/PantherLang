from debug_adapter.event_bus import EventBus
from debug_adapter.event_dispatcher import EventDispatcher
from debug_adapter.response_dispatcher import ResponseDispatcher


def test_event_dispatcher_emits_and_queues_process_event():
    bus = EventBus()
    dispatcher = EventDispatcher(bus)
    event = dispatcher.process(
        name="main.pan",
        command=["Panther", "run", "main.pan"],
        state="running",
        execution={"status": "ready"},
        request_seq=7,
    )
    assert event["type"] == "event"
    assert event["event"] == "process"
    assert event["request_seq"] == 7
    assert event["body"]["execution"]["status"] == "ready"
    assert len(bus) == 1
    assert bus.drain()[0] == event
    assert len(bus) == 0


def test_event_dispatcher_control_events():
    dispatcher = EventDispatcher()
    assert dispatcher.continued()["event"] == "continued"
    paused = dispatcher.stopped("pause", status="paused")
    assert paused["event"] == "stopped"
    assert paused["body"]["reason"] == "pause"
    assert dispatcher.terminated()["event"] == "terminated"
    assert dispatcher.exited()["event"] == "exited"


def test_response_dispatcher_preserves_events_and_normalizes_responses():
    responses = ResponseDispatcher()
    event = {"type": "event", "event": "continued"}
    assert responses.normalize(event, request_seq=5, command="continue")["event"] == "continued"

    response = responses.success("initialize", request_seq=1, body={"ok": True})
    assert response["type"] == "response"
    assert response["success"] is True
    assert response["body"]["ok"] is True

    error = responses.error("bad", request_seq=2, message="no")
    assert error["success"] is False
    assert error["message"] == "no"
