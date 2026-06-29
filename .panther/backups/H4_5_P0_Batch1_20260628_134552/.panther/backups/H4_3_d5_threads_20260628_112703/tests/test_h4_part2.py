from debug_adapter.launcher import PantherProgramLauncher
from debug_adapter.server import DebugServer
from debug_adapter.session import DebugSession
from debug_adapter.state_machine import InvalidStateTransition, SessionState, SessionStateMachine


def test_session_lifecycle_initialize_configure_launch_terminate_disconnect():
    server = DebugServer()

    initialize = server.initialize({"adapterID": "panther"})
    assert initialize["success"] is True
    assert initialize["body"]["supportsConfigurationDoneRequest"] is True
    assert server.session.state == "initialized"

    configuration_done = server.configuration_done()
    assert configuration_done["success"] is True
    assert server.session.state == "configured"

    launch = server.launch({"program": "examples/hello.pan", "args": ["--demo"], "dryRun": True})
    assert launch["event"] == "process"
    assert launch["body"]["state"] == "running"
    assert launch["body"]["command"] == ["Panther", "run", "examples/hello.pan", "--demo"]

    terminated = server.terminate()
    assert terminated["event"] == "terminated"
    assert server.session.state == "terminated"

    exited = server.disconnect()
    assert exited["event"] == "exited"
    assert server.session.state == "disconnected"


def test_launcher_builds_panther_run_command_without_starting_process():
    launcher = PantherProgramLauncher()
    result = launcher.launch("main.pan", args=["one", "two"], dry_run=True)
    assert result.started is False
    assert result.pid is None
    assert result.command == ["Panther", "run", "main.pan", "one", "two"]


def test_state_machine_rejects_invalid_transition():
    machine = SessionStateMachine()
    try:
        machine.transition(SessionState.RUNNING)
    except InvalidStateTransition as exc:
        assert "created -> running" in str(exc)
    else:
        raise AssertionError("invalid transition was not rejected")
