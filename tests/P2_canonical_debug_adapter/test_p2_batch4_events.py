from debug_adapter_rebuilt.event_bus import EventBus
from debug_adapter_rebuilt.event_dispatcher import EventDispatcher


def test_event_bus_emit_len_drain_contract():
    bus = EventBus()
    assert len(bus) == 0
    event = {"type": "event", "event": "output", "body": {"output": "ok"}}
    assert bus.emit(event) == event
    assert len(bus) == 1
    assert list(bus) == [event]
    assert bus.drain() == [event]
    assert len(bus) == 0


def test_process_event_accepts_server_signature_and_preserves_request_seq():
    bus = EventBus()
    dispatcher = EventDispatcher(bus)

    event = dispatcher.process(
        name="main.pan",
        pid=123,
        command=["Panther", "run", "main.pan"],
        state="running",
        execution={"status": "ready"},
        request_seq=7,
    )

    assert event["type"] == "event"
    assert event["event"] == "process"
    assert event["request_seq"] == 7
    assert event["body"]["systemProcessId"] == 123
    assert event["body"]["execution"]["status"] == "ready"
    assert len(bus) == 1
    assert bus.drain()[0] == event


def test_control_events():
    bus = EventBus()
    dispatcher = EventDispatcher(bus)

    continued = dispatcher.continued(request_seq=1)
    paused = dispatcher.stopped(reason="pause", request_seq=2)
    terminated = dispatcher.terminated(request_seq=3)

    assert continued["event"] == "continued"
    assert paused["event"] == "stopped"
    assert paused["body"]["reason"] == "pause"
    assert terminated["event"] == "terminated"
    assert [e["request_seq"] for e in bus.drain()] == [1, 2, 3]
