#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, field, asdict
from typing import Any

from runtime.memory.memory_store import NativeMemoryStore


@dataclass
class RuntimeContext:
    session_id: str
    state: str = "created"
    memory: dict[str, Any] = field(default_factory=dict)
    native_memory: NativeMemoryStore = field(default_factory=NativeMemoryStore)

    def set(self, key: str, value: Any) -> None:
        self.memory[key] = value
        self.native_memory.set(key, value)

    def get(self, key: str, default: Any = None) -> Any:
        return self.native_memory.get(key) if self.native_memory.has(key) else self.memory.get(key, default)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
