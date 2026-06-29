from debug_adapter.event_dispatcher import EventDispatcher
from debug_adapter.event_merge import EventMergeEngine


def test_f5_initialized_event_contract():
    dispatcher = EventDispatcher()
    event = dispatcher.initialized()

    assert event["type"] == "event"
    assert event["event"] == "initialized"
    assert EventMergeEngine().assert_event_contract(event) is True


def test_f5_process_event_contract():
    dispatcher = EventDispatcher()
    event = dispatcher.process(name="demo.panther", system_process_id=123)

    assert event["type"] == "event"
    assert event["event"] == "process"
    assert event["body"]["name"] == "demo.panther"
    assert event["body"]["systemProcessId"] == 123
    assert event["body"]["isLocalProcess"] is True
    assert event["body"]["startMethod"] == "launch"


def test_f5_continued_event_contract():
    dispatcher = EventDispatcher()
    event = dispatcher.continued(thread_id=7)

    assert event["type"] == "event"
    assert event["event"] == "continued"
    assert event["body"]["threadId"] == 7
    assert event["body"]["allThreadsContinued"] is True


def test_f5_stopped_event_contract():
    dispatcher = EventDispatcher()
    event = dispatcher.stopped(reason="pause", thread_id=9)

    assert event["type"] == "event"
    assert event["event"] == "stopped"
    assert event["body"]["reason"] == "pause"
    assert event["body"]["threadId"] == 9
    assert event["body"]["allThreadsStopped"] is True


def test_f5_terminated_and_exited_event_contract():
    dispatcher = EventDispatcher()

    terminated = dispatcher.terminated()
    exited = dispatcher.exited(exit_code=0)

    assert terminated["type"] == "event"
    assert terminated["event"] == "terminated"

    assert exited["type"] == "event"
    assert exited["event"] == "exited"
    assert exited["body"]["exitCode"] == 0


def test_f5_output_event_contract():
    dispatcher = EventDispatcher()
    event = dispatcher.output("hello panther", category="stdout")

    assert event["type"] == "event"
    assert event["event"] == "output"
    assert event["body"]["category"] == "stdout"
    assert event["body"]["output"] == "hello panther"


def test_f5_clean_event_sequence_for_h4_2_flow():
    dispatcher = EventDispatcher()

    sequence = [
        dispatcher.initialized(),
        dispatcher.process(name="demo.panther"),
        dispatcher.continued(),
        dispatcher.stopped(reason="pause"),
        dispatcher.continued(),
        dispatcher.stopped(reason="step"),
        dispatcher.terminated(),
        dispatcher.exited(0),
    ]

    names = [item["event"] for item in sequence]

    assert names == [
        "initialized",
        "process",
        "continued",
        "stopped",
        "continued",
        "stopped",
        "terminated",
        "exited",
    ]

    for item in sequence:
        assert item["type"] == "event"
        assert EventMergeEngine().assert_event_contract(item) is True
