#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass, asdict
from time import time
from typing import Any


@dataclass
class MemoryCell:
    key: str
    value: Any
    memory_type: str
    created_at: float
    updated_at: float

    @classmethod
    def create(cls, key: str, value: Any, memory_type: str = "runtime") -> "MemoryCell":
        now = time()
        return cls(key=key, value=value, memory_type=memory_type, created_at=now, updated_at=now)

    def update(self, value: Any) -> None:
        self.value = value
        self.updated_at = time()

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
