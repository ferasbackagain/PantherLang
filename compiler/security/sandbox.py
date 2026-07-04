from __future__ import annotations

import os
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


class SandboxViolation(Exception):
    pass


@dataclass
class ResourceLimits:
    max_execution_time: float = 30.0
    max_memory_mb: int = 256
    max_file_size_mb: int = 10
    allowed_read_paths: set[str] | None = None
    allowed_write_paths: set[str] | None = None
    denied_path_patterns: list[str] = field(default_factory=lambda: [
        "/etc/shadow", "/etc/passwd", "/etc/sudoers",
        "/root/", "/home/*/.ssh/", "/home/*/.gnupg/",
    ])
    network_allowed: bool = False
    exec_allowed: bool = False


class Sandbox:
    def __init__(self, limits: ResourceLimits | None = None) -> None:
        self._limits = limits or ResourceLimits()
        self._start_time: float = 0.0

    def __enter__(self) -> Sandbox:
        self._start_time = time.time()
        return self

    def __exit__(self, *args: Any) -> None:
        pass

    def check_time_limit(self) -> None:
        if self._limits.max_execution_time > 0:
            elapsed = time.time() - self._start_time
            if elapsed > self._limits.max_execution_time:
                raise SandboxViolation(
                    f"Execution time limit ({self._limits.max_execution_time}s) exceeded"
                )

    def check_file_read(self, path: str) -> str:
        resolved = str(Path(path).resolve())
        if self._limits.allowed_read_paths is not None:
            if not any(resolved.startswith(p) for p in self._limits.allowed_read_paths):
                raise SandboxViolation(f"Read access denied: {path}")
        for denied in self._limits.denied_path_patterns:
            if denied in resolved:
                raise SandboxViolation(f"Read access denied to sensitive path: {path}")
        return resolved

    def check_file_write(self, path: str) -> str:
        resolved = str(Path(path).resolve())
        if self._limits.allowed_write_paths is not None:
            if not any(resolved.startswith(p) for p in self._limits.allowed_write_paths):
                raise SandboxViolation(f"Write access denied: {path}")
        for denied in self._limits.denied_path_patterns:
            if denied in resolved:
                raise SandboxViolation(f"Write access denied to sensitive path: {path}")
        return resolved

    def check_network(self) -> None:
        if not self._limits.network_allowed:
            raise SandboxViolation("Network access is not allowed")

    def check_exec(self) -> None:
        if not self._limits.exec_allowed:
            raise SandboxViolation("Process execution is not allowed")

    def check_file_size(self, size_bytes: int) -> None:
        max_bytes = self._limits.max_file_size_mb * 1024 * 1024
        if size_bytes > max_bytes:
            raise SandboxViolation(
                f"File size ({size_bytes / 1024 / 1024:.1f}MB) exceeds limit "
                f"({self._limits.max_file_size_mb}MB)"
            )


class ReadOnlySandbox(Sandbox):
    def __init__(self, allowed_paths: list[str] | None = None) -> None:
        limits = ResourceLimits(
            allowed_read_paths=set(allowed_paths) if allowed_paths else None,
            allowed_write_paths=set(),
            network_allowed=False,
            exec_allowed=False,
        )
        super().__init__(limits)


class SafeExecSandbox(Sandbox):
    def __init__(self, allowed_paths: list[str] | None = None) -> None:
        limits = ResourceLimits(
            allowed_read_paths=set(allowed_paths) if allowed_paths else None,
            allowed_write_paths=set(allowed_paths) if allowed_paths else None,
            network_allowed=False,
            exec_allowed=False,
        )
        super().__init__(limits)
