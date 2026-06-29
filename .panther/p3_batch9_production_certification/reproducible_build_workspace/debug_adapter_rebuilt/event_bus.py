from __future__ import annotations

from typing import Any, Dict, Iterator, List


class EventBus:
    """Canonical in-memory event queue for DAP events."""

    def __init__(self):
        self._events: List[Dict[str, Any]] = []

    def emit(self, event: Dict[str, Any]) -> Dict[str, Any]:
        if not isinstance(event, dict):
            raise TypeError("event must be dict")
        self._events.append(event)
        return event

    publish = emit
    push = emit
    append = emit

    def drain(self) -> List[Dict[str, Any]]:
        events = list(self._events)
        self._events.clear()
        return events

    def peek(self) -> List[Dict[str, Any]]:
        return list(self._events)

    def __len__(self) -> int:
        return len(self._events)

    def __iter__(self) -> Iterator[Dict[str, Any]]:
        return iter(self._events)
