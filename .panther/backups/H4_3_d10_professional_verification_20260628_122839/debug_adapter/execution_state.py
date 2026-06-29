from enum import Enum


class ExecutionStatus(str, Enum):
    CREATED = "created"
    READY = "ready"
    RUNNING = "running"
    PAUSED = "paused"
    STOPPED = "stopped"
    TERMINATED = "terminated"


class ExecutionTransitionError(RuntimeError):
    pass


class ExecutionStateMachine:
    VALID_TRANSITIONS = {
        ExecutionStatus.CREATED: {ExecutionStatus.READY, ExecutionStatus.TERMINATED},
        ExecutionStatus.READY: {ExecutionStatus.RUNNING, ExecutionStatus.STOPPED, ExecutionStatus.TERMINATED},
        ExecutionStatus.RUNNING: {ExecutionStatus.PAUSED, ExecutionStatus.STOPPED, ExecutionStatus.TERMINATED},
        ExecutionStatus.PAUSED: {ExecutionStatus.RUNNING, ExecutionStatus.STOPPED, ExecutionStatus.TERMINATED},
        ExecutionStatus.STOPPED: {ExecutionStatus.RUNNING, ExecutionStatus.TERMINATED},
        ExecutionStatus.TERMINATED: set(),
    }

    def __init__(self):
        self.status = ExecutionStatus.CREATED

    def transition(self, next_status):
        next_status = ExecutionStatus(next_status)
        if next_status not in self.VALID_TRANSITIONS[self.status]:
            raise ExecutionTransitionError(
                f"invalid execution transition: {self.status.value} -> {next_status.value}"
            )
        self.status = next_status
        return self.status

    @property
    def value(self):
        return self.status.value

    def is_terminal(self):
        return self.status == ExecutionStatus.TERMINATED
