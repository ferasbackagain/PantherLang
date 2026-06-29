from __future__ import annotations

from typing import Any, Dict, List, Optional

from .event_bus import EventBus


class EventDispatcher:
    """Canonical DAP event dispatcher."""

    def __init__(self, bus: Optional[EventBus] = None):
        self.bus = bus if bus is not None else EventBus()

    def _emit(self, event: Dict[str, Any]) -> Dict[str, Any]:
        self.bus.emit(event)
        return event

    def process(
        self,
        name: str,
        pid: Optional[int] = None,
        command: Optional[List[str]] = None,
        state: str = "running",
        execution: Optional[Dict[str, Any]] = None,
        request_seq: Optional[int] = None,
        **extra: Any,
    ) -> Dict[str, Any]:
        body: Dict[str, Any] = {
            "name": name,
            "systemProcessId": 0 if pid is None else pid,
            "isLocalProcess": True,
            "startMethod": "launch",
        }
        if command is not None:
            body["command"] = command
        if state is not None:
            body["state"] = state
        if execution is not None:
            body["execution"] = execution
        body.update(extra)

        event: Dict[str, Any] = {
            "type": "event",
            "event": "process",
            "body": body,
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)

    def continued(self, thread_id: int = 1, all_threads_continued: bool = True, request_seq: Optional[int] = None) -> Dict[str, Any]:
        event: Dict[str, Any] = {
            "type": "event",
            "event": "continued",
            "body": {
                "threadId": thread_id,
                "allThreadsContinued": all_threads_continued,
            },
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)

    def stopped(self, reason: str = "pause", thread_id: int = 1, request_seq: Optional[int] = None) -> Dict[str, Any]:
        event: Dict[str, Any] = {
            "type": "event",
            "event": "stopped",
            "body": {
                "reason": reason,
                "threadId": thread_id,
                "allThreadsStopped": True,
            },
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)

    def terminated(self, restart: bool = False, request_seq: Optional[int] = None) -> Dict[str, Any]:
        event: Dict[str, Any] = {
            "type": "event",
            "event": "terminated",
            "body": {
                "restart": restart,
            },
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)

    def output(self, text: str, category: str = "console", request_seq: Optional[int] = None) -> Dict[str, Any]:
        event: Dict[str, Any] = {
            "type": "event",
            "event": "output",
            "body": {
                "category": category,
                "output": text,
            },
        }
        if request_seq is not None:
            event["request_seq"] = request_seq
        return self._emit(event)
