from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass(frozen=True, order=True)
class SourceLocation:
    """Represents a normalized source location in a Panther source file."""

    path: str
    line: int
    column: int = 1

    def __post_init__(self):
        if not self.path or not str(self.path).strip():
            raise ValueError("source path is required")
        if int(self.line) < 1:
            raise ValueError("line must be >= 1")
        if int(self.column) < 1:
            raise ValueError("column must be >= 1")
        object.__setattr__(self, "path", self.normalize_path(self.path))
        object.__setattr__(self, "line", int(self.line))
        object.__setattr__(self, "column", int(self.column))

    @staticmethod
    def normalize_path(path: str) -> str:
        text = str(path).replace("file://", "")
        return str(Path(text).expanduser())

    @property
    def key(self) -> tuple[str, int, int]:
        return (self.path, self.line, self.column)

    def to_dap_source(self) -> dict:
        return {"name": Path(self.path).name, "path": self.path}


@dataclass(frozen=True)
class SourceRange:
    start: SourceLocation
    end: Optional[SourceLocation] = None

    def contains_line(self, line: int) -> bool:
        if self.end is None:
            return self.start.line == line
        return self.start.line <= line <= self.end.line
