from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, Optional

from .locations import SourceLocation
from .validation import BreakpointValidationError, SourceLocationValidator


@dataclass
class SourceFileInfo:
    path: str
    uri: str
    line_count: int
    executable_lines: set[int] = field(default_factory=set)

    def to_dict(self) -> dict:
        return {
            "path": self.path,
            "uri": self.uri,
            "lineCount": self.line_count,
            "executableLines": sorted(self.executable_lines),
        }


class PantherSourceMap:
    """Maps Panther source files and validates executable breakpoint lines."""

    def __init__(self, validator: SourceLocationValidator | None = None):
        self.validator = validator or SourceLocationValidator()
        self._sources: Dict[str, SourceFileInfo] = {}

    def normalize_uri(self, source: dict | str) -> str:
        if isinstance(source, dict):
            raw = source.get("path") or source.get("sourceReference") or source.get("name")
        else:
            raw = source
        if raw is None:
            raise BreakpointValidationError("source path is required")
        return SourceLocation.normalize_path(str(raw))

    def register_file(self, path: str, text: str | None = None, require_exists: bool = False) -> SourceFileInfo:
        normalized = self.validator.validate_path(path, require_exists=require_exists)
        if text is None:
            p = Path(normalized)
            text = p.read_text(encoding="utf-8", errors="replace") if p.exists() else ""
        lines = text.splitlines()
        executable = self._detect_executable_lines(lines)
        info = SourceFileInfo(
            path=normalized,
            uri=Path(normalized).as_uri() if Path(normalized).is_absolute() else normalized,
            line_count=len(lines),
            executable_lines=executable,
        )
        self._sources[normalized] = info
        return info

    def _detect_executable_lines(self, lines: Iterable[str]) -> set[int]:
        executable = set()
        for idx, line in enumerate(lines, start=1):
            stripped = line.strip()
            if not stripped:
                continue
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            executable.add(idx)
        return executable

    def get(self, path: str) -> Optional[SourceFileInfo]:
        return self._sources.get(SourceLocation.normalize_path(path))

    def ensure_registered(self, path: str, require_exists: bool = False) -> SourceFileInfo:
        normalized = SourceLocation.normalize_path(path)
        return self._sources.get(normalized) or self.register_file(normalized, require_exists=require_exists)

    def resolve_breakpoint_line(self, path: str, requested_line: int, require_exists: bool = False) -> tuple[int, bool, str | None]:
        info = self.ensure_registered(path, require_exists=require_exists)
        requested_line = self.validator.validate_line(requested_line, info.path, require_exists=False)

        if info.line_count and requested_line > info.line_count:
            return requested_line, False, f"line {requested_line} exceeds file length {info.line_count}"

        if not info.executable_lines:
            return requested_line, True, None

        if requested_line in info.executable_lines:
            return requested_line, True, None

        later = [line for line in sorted(info.executable_lines) if line >= requested_line]
        if later:
            return later[0], True, f"moved breakpoint from non-executable line {requested_line} to {later[0]}"

        earlier = [line for line in sorted(info.executable_lines, reverse=True) if line < requested_line]
        if earlier:
            return earlier[0], True, f"moved breakpoint from non-executable line {requested_line} to {earlier[0]}"

        return requested_line, False, "no executable lines found"

    def to_dict(self) -> dict:
        return {path: info.to_dict() for path, info in sorted(self._sources.items())}
