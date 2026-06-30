"""Task primitives for PantherLang async execution.

The Phase 6.5 runtime intentionally uses Python's standard asyncio engine as
its portable host implementation while exposing Panther-specific task metadata,
state transitions, diagnostics, and verification-friendly reports.
"""

from __future__ import annotations

import asyncio
import inspect
import time
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Awaitable, Callable, Dict, Optional


class TaskState(str, Enum):
    CREATED = "created"
    SCHEDULED = "scheduled"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    TIMED_OUT = "timed_out"


@dataclass(slots=True)
class PantherTaskResult:
    task_id: str
    state: TaskState
    value: Any = None
    error: Optional[str] = None
    started_at: Optional[float] = None
    finished_at: Optional[float] = None
    duration_ms: float = 0.0
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "task_id": self.task_id,
            "state": self.state.value,
            "value": self.value,
            "error": self.error,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "duration_ms": round(self.duration_ms, 3),
            "metadata": dict(self.metadata),
        }


@dataclass(slots=True)
class PantherAsyncTask:
    task_id: str
    operation: Callable[..., Any] | Awaitable[Any]
    args: tuple[Any, ...] = field(default_factory=tuple)
    kwargs: Dict[str, Any] = field(default_factory=dict)
    priority: int = 100
    timeout_seconds: Optional[float] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    state: TaskState = TaskState.CREATED

    def __post_init__(self) -> None:
        if not self.task_id or not isinstance(self.task_id, str):
            raise ValueError("task_id must be a non-empty string")
        if self.priority < 0:
            raise ValueError("priority must be >= 0")
        if self.timeout_seconds is not None and self.timeout_seconds <= 0:
            raise ValueError("timeout_seconds must be positive when provided")

    async def run(self) -> PantherTaskResult:
        started_at = time.time()
        self.state = TaskState.RUNNING
        try:
            value = await self._execute_with_timeout()
            finished_at = time.time()
            self.state = TaskState.COMPLETED
            return PantherTaskResult(
                task_id=self.task_id,
                state=self.state,
                value=value,
                started_at=started_at,
                finished_at=finished_at,
                duration_ms=(finished_at - started_at) * 1000,
                metadata=dict(self.metadata),
            )
        except asyncio.TimeoutError:
            finished_at = time.time()
            self.state = TaskState.TIMED_OUT
            return PantherTaskResult(
                task_id=self.task_id,
                state=self.state,
                error="task timed out",
                started_at=started_at,
                finished_at=finished_at,
                duration_ms=(finished_at - started_at) * 1000,
                metadata=dict(self.metadata),
            )
        except asyncio.CancelledError:
            finished_at = time.time()
            self.state = TaskState.CANCELLED
            return PantherTaskResult(
                task_id=self.task_id,
                state=self.state,
                error="task cancelled",
                started_at=started_at,
                finished_at=finished_at,
                duration_ms=(finished_at - started_at) * 1000,
                metadata=dict(self.metadata),
            )
        except Exception as exc:  # pragma: no cover - verified by negative tests
            finished_at = time.time()
            self.state = TaskState.FAILED
            return PantherTaskResult(
                task_id=self.task_id,
                state=self.state,
                error=f"{type(exc).__name__}: {exc}",
                started_at=started_at,
                finished_at=finished_at,
                duration_ms=(finished_at - started_at) * 1000,
                metadata=dict(self.metadata),
            )

    async def _execute_with_timeout(self) -> Any:
        coroutine = self._coerce_to_coroutine()
        if self.timeout_seconds is None:
            return await coroutine
        return await asyncio.wait_for(coroutine, timeout=self.timeout_seconds)

    async def _coerce_to_coroutine(self) -> Any:
        if inspect.isawaitable(self.operation):
            return await self.operation
        if not callable(self.operation):
            raise TypeError("operation must be callable or awaitable")
        value = self.operation(*self.args, **self.kwargs)
        if inspect.isawaitable(value):
            return await value
        return value
