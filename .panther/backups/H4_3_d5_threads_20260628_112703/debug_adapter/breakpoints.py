from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional

from .locations import SourceLocation
from .validation import BreakpointValidationError, SourceLocationValidator


@dataclass
class Breakpoint:
    id: int
    location: SourceLocation
    enabled: bool = True
    verified: bool = True
    condition: Optional[str] = None
    hit_condition: Optional[str] = None
    log_message: Optional[str] = None
    message: Optional[str] = None
    metadata: dict = field(default_factory=dict)

    @property
    def line(self) -> int:
        return self.location.line

    @property
    def column(self) -> int:
        return self.location.column

    @property
    def source_path(self) -> str:
        return self.location.path

    def to_dap(self) -> dict:
        item = {
            "id": self.id,
            "verified": bool(self.verified),
            "line": self.line,
            "column": self.column,
            "source": self.location.to_dap_source(),
        }
        if self.message:
            item["message"] = self.message
        return item

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "path": self.source_path,
            "line": self.line,
            "column": self.column,
            "enabled": self.enabled,
            "verified": self.verified,
            "condition": self.condition,
            "hitCondition": self.hit_condition,
            "logMessage": self.log_message,
            "message": self.message,
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Breakpoint":
        return cls(
            id=int(data["id"]),
            location=SourceLocation(data["path"], int(data["line"]), int(data.get("column", 1))),
            enabled=bool(data.get("enabled", True)),
            verified=bool(data.get("verified", True)),
            condition=data.get("condition"),
            hit_condition=data.get("hitCondition"),
            log_message=data.get("logMessage"),
            message=data.get("message"),
            metadata=dict(data.get("metadata") or {}),
        )


class BreakpointManager:
    """Manages Panther breakpoints independent of execution control."""

    def __init__(self, validator: SourceLocationValidator | None = None):
        self.validator = validator or SourceLocationValidator()
        self._breakpoints: Dict[int, Breakpoint] = {}
        self._next_id = 1

    def _allocate_id(self) -> int:
        value = self._next_id
        self._next_id += 1
        return value

    def clear(self, source_path: str | None = None) -> None:
        if source_path is None:
            self._breakpoints.clear()
            return
        normalized = SourceLocation.normalize_path(source_path)
        for bp_id in [bp.id for bp in self._breakpoints.values() if bp.source_path == normalized]:
            del self._breakpoints[bp_id]

    def set_breakpoints(self, source_path: str, breakpoints: Iterable[dict], require_exists: bool = False) -> list[Breakpoint]:
        normalized = self.validator.validate_path(source_path, require_exists=require_exists)
        self.clear(normalized)
        result: list[Breakpoint] = []

        for raw in breakpoints or []:
            line = raw.get("line") if isinstance(raw, dict) else raw
            column = raw.get("column", 1) if isinstance(raw, dict) else 1
            try:
                location = self.validator.validate_location(normalized, line, column, require_exists=require_exists)
                breakpoint = Breakpoint(
                    id=self._allocate_id(),
                    location=location,
                    enabled=True,
                    verified=True,
                    condition=raw.get("condition") if isinstance(raw, dict) else None,
                    hit_condition=raw.get("hitCondition") if isinstance(raw, dict) else None,
                    log_message=raw.get("logMessage") if isinstance(raw, dict) else None,
                )
            except BreakpointValidationError as exc:
                fallback_line = int(line) if str(line).isdigit() and int(line) > 0 else 1
                breakpoint = Breakpoint(
                    id=self._allocate_id(),
                    location=SourceLocation(normalized, fallback_line, 1),
                    enabled=False,
                    verified=False,
                    message=str(exc),
                )
            self._breakpoints[breakpoint.id] = breakpoint
            result.append(breakpoint)
        return result

    def add_breakpoint(self, source_path: str, line: int, column: int = 1) -> Breakpoint:
        return self.set_breakpoints(source_path, [{"line": line, "column": column}])[-1]

    def remove_breakpoint(self, breakpoint_id: int) -> bool:
        return self._breakpoints.pop(int(breakpoint_id), None) is not None

    def enable_breakpoint(self, breakpoint_id: int, enabled: bool = True) -> Breakpoint:
        breakpoint = self._breakpoints[int(breakpoint_id)]
        breakpoint.enabled = bool(enabled)
        return breakpoint

    def list_breakpoints(self, source_path: str | None = None) -> list[Breakpoint]:
        values = list(self._breakpoints.values())
        if source_path is not None:
            normalized = SourceLocation.normalize_path(source_path)
            values = [bp for bp in values if bp.source_path == normalized]
        return sorted(values, key=lambda bp: (bp.source_path, bp.line, bp.column, bp.id))

    def find_at(self, source_path: str, line: int) -> list[Breakpoint]:
        normalized = SourceLocation.normalize_path(source_path)
        return [bp for bp in self.list_breakpoints(normalized) if bp.enabled and bp.verified and bp.line == int(line)]

    def load(self, store) -> list[Breakpoint]:
        self._breakpoints.clear()
        loaded = store.load()
        for bp in loaded:
            self._breakpoints[bp.id] = bp
            self._next_id = max(self._next_id, bp.id + 1)
        return self.list_breakpoints()

    def save(self, store):
        return store.save(self.list_breakpoints())
