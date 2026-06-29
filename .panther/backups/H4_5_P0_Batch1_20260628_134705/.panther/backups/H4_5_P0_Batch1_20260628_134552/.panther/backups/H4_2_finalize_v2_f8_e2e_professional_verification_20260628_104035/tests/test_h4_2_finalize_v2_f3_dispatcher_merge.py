from debug_adapter.dispatcher_contract import (
    REQUIRED_COMMANDS,
    dispatch_smoke_sequence,
    get_dispatcher_commands,
    validate_dispatcher_contract,
)
from debug_adapter.finalize_v2_status import H4_2_FINALIZE_V2


def test_dispatcher_exposes_required_commands():
    commands = set(get_dispatcher_commands())
    for command in REQUIRED_COMMANDS:
        assert command in commands
    assert validate_dispatcher_contract() is True


def test_dispatcher_smoke_sequence_uses_v2_event_routing():
    results = dispatch_smoke_sequence()

    assert results[0]["success"] is True
    assert results[1]["success"] is True
    assert results[2]["success"] is True

    launch = results[3]
    assert launch["type"] == "event"
    assert launch["event"] == "process"

    continued = results[4]
    assert continued["type"] == "event"
    assert continued["event"] == "continued"

    paused = results[5]
    assert paused["type"] == "event"
    assert paused["event"] == "stopped"

    stopped = results[6]
    assert stopped["type"] == "event"
    assert stopped["event"] == "stopped"

    assert results[7]["event"] == "terminated"
    assert results[8]["event"] == "exited"


def test_f3_status_marker():
    assert H4_2_FINALIZE_V2["f3_dispatcher_merge"] is True
