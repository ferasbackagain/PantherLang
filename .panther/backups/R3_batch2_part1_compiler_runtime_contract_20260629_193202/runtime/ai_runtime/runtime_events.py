#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, asdict
from time import time
from typing import Any


@dataclass
class RuntimeEvent:
    name: str
    payload: dict[str, Any]
    timestamp: float

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


class RuntimeEventBus:
    def __init__(self, max_events: int = 1000) -> None:
        self.max_events = max_events
        self.events: list[RuntimeEvent] = []

    def emit(self, name: str, payload: dict[str, Any] | None = None) -> RuntimeEvent:
        event = RuntimeEvent(name=name, payload=payload or {}, timestamp=time())
        self.events.append(event)
        if len(self.events) > self.max_events:
            self.events = self.events[-self.max_events:]
        return event

    def list_events(self) -> list[dict[str, Any]]:
        return [event.to_dict() for event in self.events]
