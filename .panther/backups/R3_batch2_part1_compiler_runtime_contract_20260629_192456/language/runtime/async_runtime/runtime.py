"""High-level PantherLang async runtime facade."""

from __future__ import annotations

import asyncio
import json
import time
from pathlib import Path
from typing import Any, Callable, Iterable, List, Optional

from .scheduler import PantherAsyncScheduler, SchedulerPolicy
from .task import PantherAsyncTask, PantherTaskResult, TaskState


class PantherAsyncRuntimeError(RuntimeError):
    pass


class PantherAsyncRuntime:
    def __init__(self, *, max_concurrency: int = 8, fail_fast: bool = False) -> None:
        self.policy = SchedulerPolicy(max_concurrency=max_concurrency, fail_fast=fail_fast)
        self.scheduler = PantherAsyncScheduler(self.policy)
        self.last_results: List[PantherTaskResult] = []
        self.created_at = time.time()

    def create_task(
        self,
        task_id: str,
        operation: Callable[..., Any],
        *args: Any,
        priority: int = 100,
        timeout_seconds: Optional[float] = None,
        metadata: Optional[dict[str, Any]] = None,
        **kwargs: Any,
    ) -> PantherAsyncTask:
        return PantherAsyncTask(
            task_id=task_id,
            operation=operation,
            args=args,
            kwargs=kwargs,
            priority=priority,
            timeout_seconds=timeout_seconds,
            metadata=metadata or {},
        )

    def submit(self, task: PantherAsyncTask) -> None:
        self.scheduler.submit(task)

    def submit_many(self, tasks: Iterable[PantherAsyncTask]) -> None:
        self.scheduler.submit_many(tasks)

    async def run_async(self) -> List[PantherTaskResult]:
        self.last_results = await self.scheduler.run_all()
        return self.last_results

    def run(self) -> List[PantherTaskResult]:
        try:
            asyncio.get_running_loop()
        except RuntimeError:
            return asyncio.run(self.run_async())
        raise PantherAsyncRuntimeError(
            "PantherAsyncRuntime.run() cannot be called from an active event loop; use run_async()."
        )

    def metrics(self) -> dict[str, Any]:
        totals: dict[str, int] = {state.value: 0 for state in TaskState}
        for result in self.last_results:
            totals[result.state.value] += 1
        return {
            "phase": "6.5",
            "runtime": "PantherAsyncRuntime",
            "created_at": self.created_at,
            "tasks_total": len(self.last_results),
            "states": totals,
            "max_concurrency": self.policy.max_concurrency,
            "fail_fast": self.policy.fail_fast,
            "duration_ms_total": round(sum(item.duration_ms for item in self.last_results), 3),
        }

    def report(self) -> dict[str, Any]:
        return {
            "metrics": self.metrics(),
            "results": [item.to_dict() for item in self.last_results],
        }

    def write_report(self, path: str | Path) -> Path:
        target = Path(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(self.report(), indent=2, sort_keys=True), encoding="utf-8")
        return target
