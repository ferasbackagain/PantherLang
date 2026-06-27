#!/usr/bin/env python3
from __future__ import annotations

from typing import Any

from runtime.memory.memory_cell import MemoryCell


class PantherMemoryError(Exception):
    pass


class NativeMemoryStore:
    def __init__(self) -> None:
        self.cells: dict[str, MemoryCell] = {}

    def set(self, key: str, value: Any, memory_type: str = "runtime") -> MemoryCell:
        self._validate_key(key)
        if key in self.cells:
            self.cells[key].update(value)
        else:
            self.cells[key] = MemoryCell.create(key, value, memory_type)
        return self.cells[key]

    def get(self, key: str) -> Any:
        self._validate_key(key)
        if key not in self.cells:
            raise PantherMemoryError(f"Memory key not found: {key}")
        return self.cells[key].value

    def has(self, key: str) -> bool:
        return key in self.cells

    def delete(self, key: str) -> None:
        self._validate_key(key)
        if key not in self.cells:
            raise PantherMemoryError(f"Memory key not found: {key}")
        del self.cells[key]

    def snapshot(self) -> dict[str, Any]:
        return {key: cell.to_dict() for key, cell in sorted(self.cells.items())}

    def _validate_key(self, key: str) -> None:
        if not key or not isinstance(key, str):
            raise PantherMemoryError("Memory key must be a non-empty string")
        if len(key) > 256:
            raise PantherMemoryError("Memory key too long")
