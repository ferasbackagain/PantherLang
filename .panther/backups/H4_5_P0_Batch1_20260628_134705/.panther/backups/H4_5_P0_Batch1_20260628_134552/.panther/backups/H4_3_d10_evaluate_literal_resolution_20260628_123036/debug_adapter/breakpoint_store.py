import json
from pathlib import Path
from typing import Iterable

from .breakpoints import Breakpoint
from .locations import SourceLocation


class BreakpointStore:
    """Small JSON persistence layer for Panther breakpoints."""

    def __init__(self, path: str | None = None):
        self.path = Path(path or ".panther_debug/breakpoints.json")

    def save(self, breakpoints: Iterable[Breakpoint]) -> Path:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        payload = [bp.to_dict() for bp in sorted(breakpoints, key=lambda b: b.id)]
        self.path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
        return self.path

    def load(self) -> list[Breakpoint]:
        if not self.path.exists():
            return []
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        return [Breakpoint.from_dict(item) for item in raw]
