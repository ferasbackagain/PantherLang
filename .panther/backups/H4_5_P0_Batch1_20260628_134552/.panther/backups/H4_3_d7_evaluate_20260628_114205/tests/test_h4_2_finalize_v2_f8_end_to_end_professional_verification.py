import json
import os
from pathlib import Path

from debug_adapter.dispatcher import RequestDispatcher


TRACE_PATH = Path(os.environ.get("PANTHER_F8_TRACE_FILE", "docs/hardening/H4_2_F8_DAP_TRACE.json"))


def _assert_response(message, seq, command, success=True):
    assert message["type"] == "response"
    assert message["request_seq"] == seq
    assert message["command"] == command
    assert message["success"] is success


def _assert_event(message, seq, event, source_command):
    assert message["type"] == "event"
    assert message["request_seq"] == seq
    assert message["event"] == event
    assert message["sourceCommand"] == source_command


def test_f8_complete_professional_debug_adapter_sequence():
    dispatcher = RequestDispatcher()
    trace = []

    def send(seq, command, arguments=None):
        request = {
            "seq": seq,
            "type": "request",
            "command": command,
        }
        if arguments is not None:
            request["arguments"] = arguments

        response = dispatcher.dispatch(request)
        trace.append({
            "request": request,
            "response": response,
        })
        return response

    initialize = send(1, "initialize", {})
    _assert_response(initialize, 1, "initialize", True)

    configuration_done = send(2, "configurationDone")
    _assert_response(configuration_done, 2, "configurationDone", True)

    set_breakpoints = send(
        3,
        "setBreakpoints",
        {
            "source": {"path": "examples/hello.pan"},
            "breakpoints": [
                {"line": 1},
                {"line": 3},
                {"line": 5},
            ],
        },
    )
    _assert_response(set_breakpoints, 3, "setBreakpoints", True)
    assert len(set_breakpoints["body"]["breakpoints"]) == 3

    launch = send(
        4,
        "launch",
        {
            "program": "examples/hello.pan",
            "dryRun": True,
        },
    )
    _assert_event(launch, 4, "process", "launch")

    continue_1 = send(5, "continue")
    _assert_event(continue_1, 5, "continued", "continue")

    pause = send(6, "pause")
    _assert_event(pause, 6, "stopped", "pause")
    assert pause["body"]["reason"] in {"pause", "user request", "paused"}

    continue_2 = send(7, "continue")
    _assert_event(continue_2, 7, "continued", "continue")

    stop = send(8, "stop")
    _assert_event(stop, 8, "stopped", "stop")

    terminate = send(9, "terminate")
    _assert_event(terminate, 9, "terminated", "terminate")

    disconnect = send(10, "disconnect")
    assert disconnect["request_seq"] == 10
    if disconnect["type"] == "event":
        assert disconnect["sourceCommand"] == "disconnect"
    else:
        assert disconnect["type"] == "response"
        assert disconnect["command"] == "disconnect"

    TRACE_PATH.parent.mkdir(parents=True, exist_ok=True)
    TRACE_PATH.write_text(json.dumps(trace, indent=2), encoding="utf-8")

    sequence = [
        item["request"]["command"]
        for item in trace
    ]

    assert sequence == [
        "initialize",
        "configurationDone",
        "setBreakpoints",
        "launch",
        "continue",
        "pause",
        "continue",
        "stop",
        "terminate",
        "disconnect",
    ]


def test_f8_debug_adapter_components_are_professionally_integrated():
    required = [
        "debug_adapter/dispatcher.py",
        "debug_adapter/server.py",
        "debug_adapter/session.py",
        "debug_adapter/response_merge.py",
        "debug_adapter/response_dispatcher.py",
        "debug_adapter/event_merge.py",
        "debug_adapter/event_dispatcher.py",
        "debug_adapter/execution_merge.py",
        "debug_adapter/execution_dispatcher.py",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing professional DAP component: {item}"


def test_f8_batch2_and_batch3_status_chain_exists():
    required = [
        ".panther/phase_status/H4_2_finalize_v2_f4_response_merge.json",
        ".panther/phase_status/H4_2_f5_event_request_seq_patch.json",
        ".panther/phase_status/H4_2_finalize_v2_f6_execution_merge.json",
        ".panther/phase_status/H4_2_finalize_v2_f7_full_regression.json",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing verified status link: {item}"
