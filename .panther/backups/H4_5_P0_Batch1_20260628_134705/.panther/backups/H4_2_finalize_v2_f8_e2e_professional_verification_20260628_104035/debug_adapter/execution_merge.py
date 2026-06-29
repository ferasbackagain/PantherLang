from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional


@dataclass(slots=True)
class ExecutionSnapshot:
    """Canonical PantherLang debug execution snapshot."""

    program: Optional[str] = None
    thread_id: int = 1
    state: str = "created"
    launched: bool = False
    configured: bool = False
    running: bool = False
    paused: bool = False
    stopped: bool = False
    terminated: bool = False
    breakpoints: List[Dict[str, Any]] = field(default_factory=list)
    last_command: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "program": self.program,
            "threadId": self.thread_id,
            "state": self.state,
            "launched": self.launched,
            "configured": self.configured,
            "running": self.running,
            "paused": self.paused,
            "stopped": self.stopped,
            "terminated": self.terminated,
            "breakpoints": list(self.breakpoints),
            "lastCommand": self.last_command,
        }


class ExecutionMergeEngine:
    """
    Final H4.2 execution merge layer.

    This layer gives H4.2 a single canonical execution-state model while
    preserving the existing dispatcher/server behavior verified in Part2B v2.
    """

    def __init__(self, thread_id: int = 1) -> None:
        self.snapshot = ExecutionSnapshot(thread_id=int(thread_id))

    def configuration_done(self) -> Dict[str, Any]:
        self.snapshot.configured = True
        self.snapshot.last_command = "configurationDone"
        if self.snapshot.state == "created":
            self.snapshot.state = "configured"
        return self.snapshot.to_dict()

    def set_breakpoints(self, breakpoints: List[Dict[str, Any]]) -> Dict[str, Any]:
        normalized: List[Dict[str, Any]] = []
        for idx, bp in enumerate(breakpoints or [], start=1):
            line = int(bp.get("line", idx))
            normalized.append({
                "id": int(bp.get("id", idx)),
                "verified": bool(bp.get("verified", True)),
                "line": line,
            })
        self.snapshot.breakpoints = normalized
        self.snapshot.last_command = "setBreakpoints"
        return {"breakpoints": normalized, "execution": self.snapshot.to_dict()}

    def launch(self, program: Optional[str] = None, dry_run: bool = False) -> Dict[str, Any]:
        self.snapshot.program = program
        self.snapshot.launched = True
        self.snapshot.running = True
        self.snapshot.paused = False
        self.snapshot.stopped = False
        self.snapshot.terminated = False
        self.snapshot.state = "running"
        self.snapshot.last_command = "launch"
        return {
            "program": program,
            "dryRun": bool(dry_run),
            "threadId": self.snapshot.thread_id,
            "state": self.snapshot.state,
            "execution": self.snapshot.to_dict(),
        }

    def continue_execution(self) -> Dict[str, Any]:
        self.snapshot.running = True
        self.snapshot.paused = False
        self.snapshot.stopped = False
        self.snapshot.state = "running"
        self.snapshot.last_command = "continue"
        return {
            "threadId": self.snapshot.thread_id,
            "state": self.snapshot.state,
            "execution": self.snapshot.to_dict(),
        }

    def pause(self) -> Dict[str, Any]:
        self.snapshot.running = False
        self.snapshot.paused = True
        self.snapshot.stopped = True
        self.snapshot.state = "paused"
        self.snapshot.last_command = "pause"
        return {
            "threadId": self.snapshot.thread_id,
            "reason": "pause",
            "state": self.snapshot.state,
            "execution": self.snapshot.to_dict(),
        }

    def stop(self) -> Dict[str, Any]:
        self.snapshot.running = False
        self.snapshot.paused = False
        self.snapshot.stopped = True
        self.snapshot.state = "stopped"
        self.snapshot.last_command = "stop"
        return {
            "threadId": self.snapshot.thread_id,
            "reason": "stop",
            "state": self.snapshot.state,
            "execution": self.snapshot.to_dict(),
        }

    def terminate(self) -> Dict[str, Any]:
        self.snapshot.running = False
        self.snapshot.paused = False
        self.snapshot.stopped = True
        self.snapshot.terminated = True
        self.snapshot.state = "terminated"
        self.snapshot.last_command = "terminate"
        return {
            "threadId": self.snapshot.thread_id,
            "state": self.snapshot.state,
            "execution": self.snapshot.to_dict(),
        }

    def disconnect(self) -> Dict[str, Any]:
        self.snapshot.running = False
        self.snapshot.paused = False
        self.snapshot.stopped = True
        self.snapshot.terminated = True
        self.snapshot.state = "disconnected"
        self.snapshot.last_command = "disconnect"
        return {
            "threadId": self.snapshot.thread_id,
            "state": self.snapshot.state,
            "execution": self.snapshot.to_dict(),
        }

    def current(self) -> Dict[str, Any]:
        return self.snapshot.to_dict()

    def assert_execution_contract(self, state: Dict[str, Any]) -> bool:
        required = {
            "program",
            "threadId",
            "state",
            "launched",
            "configured",
            "running",
            "paused",
            "stopped",
            "terminated",
            "breakpoints",
            "lastCommand",
        }
        missing = required.difference(state.keys())
        if missing:
            raise AssertionError(f"execution state missing keys: {sorted(missing)}")
        return True
