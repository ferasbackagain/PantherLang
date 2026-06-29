from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Optional


@dataclass(slots=True)
class EventEnvelope:
    """Canonical PantherLang Debug Adapter Protocol event envelope."""

    event: str
    body: Dict[str, Any] = field(default_factory=dict)

    def to_dap(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "type": "event",
            "event": self.event,
        }
        if self.body:
            payload["body"] = dict(self.body)
        return payload


class EventMergeEngine:
    """
    Final event merge layer for H4.2.

    Centralizes Debug Adapter Protocol events used by the dispatcher and
    execution-control pipeline.

    Supported professional H4.2 event flow:
    - initialized
    - process
    - continued
    - stopped
    - terminated
    - exited
    - output
    """

    def event(self, name: str, body: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        return EventEnvelope(event=name, body=body or {}).to_dap()

    def initialized(self) -> Dict[str, Any]:
        return self.event("initialized")

    def process(
        self,
        name: str = "PantherLang Program",
        system_process_id: int = 0,
        start_method: str = "launch",
    ) -> Dict[str, Any]:
        return self.event(
            "process",
            {
                "name": name,
                "systemProcessId": int(system_process_id),
                "isLocalProcess": True,
                "startMethod": start_method,
            },
        )

    def continued(self, thread_id: int = 1, all_threads_continued: bool = True) -> Dict[str, Any]:
        return self.event(
            "continued",
            {
                "threadId": int(thread_id),
                "allThreadsContinued": bool(all_threads_continued),
            },
        )

    def stopped(
        self,
        reason: str = "pause",
        thread_id: int = 1,
        all_threads_stopped: bool = True,
    ) -> Dict[str, Any]:
        return self.event(
            "stopped",
            {
                "reason": reason,
                "threadId": int(thread_id),
                "allThreadsStopped": bool(all_threads_stopped),
            },
        )

    def terminated(self, restart: bool = False) -> Dict[str, Any]:
        if restart:
            return self.event("terminated", {"restart": True})
        return self.event("terminated")

    def exited(self, exit_code: int = 0) -> Dict[str, Any]:
        return self.event("exited", {"exitCode": int(exit_code)})

    def output(self, output: str, category: str = "console") -> Dict[str, Any]:
        return self.event(
            "output",
            {
                "category": category,
                "output": str(output),
            },
        )

    def assert_event_contract(self, message: Dict[str, Any]) -> bool:
        if not isinstance(message, dict):
            raise AssertionError("event must be a dictionary")
        if message.get("type") != "event":
            raise AssertionError("event type must be 'event'")
        if "event" not in message:
            raise AssertionError("event missing event name")
        return True
