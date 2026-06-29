#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Any

from runtime.memory.memory_store import NativeMemoryStore


@dataclass
class AgentContext:
    agent_id: str
    name: str
    role: str
    memory: NativeMemoryStore = field(default_factory=NativeMemoryStore)
    state: dict[str, Any] = field(default_factory=dict)

    def remember(self, key: str, value: Any) -> None:
        self.memory.set(f"{self.name}.{key}", value)

    def recall(self, key: str) -> Any:
        return self.memory.get(f"{self.name}.{key}")

    def to_dict(self) -> dict[str, Any]:
        return {
            "agent_id": self.agent_id,
            "name": self.name,
            "role": self.role,
            "state": self.state,
            "memory": self.memory.snapshot(),
        }
