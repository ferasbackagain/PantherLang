from dataclasses import dataclass, field
from typing import Any, Dict, Optional

from .execution_state import ExecutionStateMachine, ExecutionStatus


@dataclass
class ExecutionSnapshot:
    status: str
    reason: str
    thread_id: int = 1
    program: Optional[str] = None
    current_line: Optional[int] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class ExecutionController:
    def __init__(self):
        self.machine = ExecutionStateMachine()
        self.program = None
        self.thread_id = 1
        self.current_line = None
        self.last_reason = "created"

    @property
    def status(self):
        return self.machine.value

    def prepare(self, program=None, current_line=1):
        self.program = program
        self.current_line = current_line
        if self.machine.status == ExecutionStatus.CREATED:
            self.machine.transition(ExecutionStatus.READY)
        self.last_reason = "prepared"
        return self.snapshot()

    def continue_execution(self):
        if self.machine.status == ExecutionStatus.CREATED:
            self.prepare()
        if self.machine.status in {ExecutionStatus.READY, ExecutionStatus.PAUSED, ExecutionStatus.STOPPED}:
            self.machine.transition(ExecutionStatus.RUNNING)
        self.last_reason = "continued"
        return self.snapshot()

    def pause(self, reason="pause"):
        if self.machine.status == ExecutionStatus.CREATED:
            self.prepare()
        if self.machine.status == ExecutionStatus.READY:
            self.machine.transition(ExecutionStatus.RUNNING)
        if self.machine.status == ExecutionStatus.RUNNING:
            self.machine.transition(ExecutionStatus.PAUSED)
        self.last_reason = reason
        return self.snapshot()

    def stop(self, reason="stop"):
        if self.machine.status == ExecutionStatus.CREATED:
            self.prepare()
        if self.machine.status in {ExecutionStatus.READY, ExecutionStatus.RUNNING, ExecutionStatus.PAUSED}:
            self.machine.transition(ExecutionStatus.STOPPED)
        self.last_reason = reason
        return self.snapshot()

    def terminate(self):
        if self.machine.status != ExecutionStatus.TERMINATED:
            if self.machine.status == ExecutionStatus.CREATED:
                self.machine.transition(ExecutionStatus.TERMINATED)
            elif self.machine.status in {
                ExecutionStatus.READY,
                ExecutionStatus.RUNNING,
                ExecutionStatus.PAUSED,
                ExecutionStatus.STOPPED,
            }:
                self.machine.transition(ExecutionStatus.TERMINATED)
        self.last_reason = "terminated"
        return self.snapshot()

    def snapshot(self):
        return ExecutionSnapshot(
            status=self.status,
            reason=self.last_reason,
            thread_id=self.thread_id,
            program=self.program,
            current_line=self.current_line,
            metadata={},
        )

    def to_body(self):
        snap = self.snapshot()
        return {
            "status": snap.status,
            "reason": snap.reason,
            "threadId": snap.thread_id,
            "program": snap.program,
            "currentLine": snap.current_line,
            "metadata": snap.metadata,
        }
