from __future__ import annotations
from typing import Any, Dict, Optional

from .event_dispatcher import EventDispatcher


class ExecutionDispatcher:
    def __init__(self, events: Optional[EventDispatcher] = None):
        self.events = events if events is not None else EventDispatcher()
        self.status = "created"
        self.program = None
        self.current_line = 1

    def prepare(self, program: str, current_line: int = 1) -> Dict[str, Any]:
        self.status = "ready"
        self.program = program
        self.current_line = current_line
        return self.to_body()

    def launch(self, program: str, command=None, request_seq: int = 0) -> Dict[str, Any]:
        self.prepare(program)
        self.status = "running"
        return self.events.process(
            name=program,
            command=command,
            state=self.status,
            execution=self.to_body(),
            request_seq=request_seq,
        )

    def continue_(self, request_seq: int = 0) -> Dict[str, Any]:
        self.status = "running"
        return self.events.continued(request_seq=request_seq)

    def pause(self, request_seq: int = 0) -> Dict[str, Any]:
        self.status = "paused"
        return self.events.stopped(reason="pause", request_seq=request_seq)

    def stop(self, request_seq: int = 0) -> Dict[str, Any]:
        self.status = "stopped"
        return self.events.stopped(reason="stop", request_seq=request_seq)

    def terminate(self, request_seq: int = 0) -> Dict[str, Any]:
        self.status = "terminated"
        return self.events.terminated(request_seq=request_seq)

    def to_body(self) -> Dict[str, Any]:
        return {
            "status": self.status,
            "program": self.program,
            "currentLine": self.current_line,
        }
