from debug_adapter.execution_controller import ExecutionController
from debug_adapter.execution_state import ExecutionStateMachine, ExecutionStatus, ExecutionTransitionError


def test_execution_controller_prepare_continue_pause_stop_terminate():
    controller = ExecutionController()
    assert controller.prepare(program="examples/hello.pan", current_line=1).status == "ready"
    assert controller.continue_execution().status == "running"
    assert controller.pause().status == "paused"
    assert controller.continue_execution().status == "running"
    assert controller.stop().status == "stopped"
    assert controller.terminate().status == "terminated"


def test_pause_from_created_prepares_and_pauses():
    controller = ExecutionController()
    paused = controller.pause(reason="manual")
    assert paused.status == "paused"
    assert paused.reason == "manual"


def test_execution_state_machine_rejects_invalid_transition():
    machine = ExecutionStateMachine()
    try:
        machine.transition(ExecutionStatus.RUNNING)
    except ExecutionTransitionError as exc:
        assert "created -> running" in str(exc)
    else:
        raise AssertionError("invalid execution transition was not rejected")
