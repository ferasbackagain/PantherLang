from pathlib import Path
from typing import Iterable

from .locations import SourceLocation


class BreakpointValidationError(ValueError):
    pass


class SourceLocationValidator:
    """Validates source paths and line numbers for Panther breakpoints."""

    def __init__(self, allowed_extensions: Iterable[str] | None = None):
        self.allowed_extensions = set(allowed_extensions or {".pan", ".panther"})

    def validate_path(self, path: str, require_exists: bool = False) -> str:
        if not path or not str(path).strip():
            raise BreakpointValidationError("source path is required")
        normalized = SourceLocation.normalize_path(path)
        suffix = Path(normalized).suffix
        if suffix and suffix not in self.allowed_extensions:
            raise BreakpointValidationError(f"unsupported Panther source extension: {suffix}")
        if require_exists and not Path(normalized).exists():
            raise BreakpointValidationError(f"source file does not exist: {normalized}")
        return normalized

    def validate_line(self, line: int, source_path: str | None = None, require_exists: bool = False) -> int:
        try:
            line = int(line)
        except Exception as exc:
            raise BreakpointValidationError("line must be an integer") from exc
        if line < 1:
            raise BreakpointValidationError("line must be >= 1")

        if source_path and require_exists:
            path = Path(SourceLocation.normalize_path(source_path))
            if path.exists():
                line_count = len(path.read_text(encoding="utf-8", errors="replace").splitlines())
                if line_count > 0 and line > line_count:
                    raise BreakpointValidationError(f"line {line} exceeds file length {line_count}")
        return line

    def validate_location(self, path: str, line: int, column: int = 1, require_exists: bool = False) -> SourceLocation:
        normalized = self.validate_path(path, require_exists=require_exists)
        valid_line = self.validate_line(line, normalized, require_exists=require_exists)
        return SourceLocation(normalized, valid_line, column)
