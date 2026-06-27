"""Priority-aware scheduler for PantherLang async runtime."""

from __future__ import annotations

import asyncio
from dataclasses import dataclass
from typing import Iterable, List

from .task import PantherAsyncTask, PantherTaskResult, TaskState


@dataclass(slots=True)
class SchedulerPolicy:
    max_concurrency: int = 8
    fail_fast: bool = False

    def __post_init__(self) -> None:
        if self.max_concurrency <= 0:
            raise ValueError("max_concurrency must be > 0")


class PantherAsyncScheduler:
    def __init__(self, policy: SchedulerPolicy | None = None) -> None:
        self.policy = policy or SchedulerPolicy()
        self._queue: List[PantherAsyncTask] = []

    def submit(self, task: PantherAsyncTask) -> None:
        if not isinstance(task, PantherAsyncTask):
            raise TypeError("submit expects a PantherAsyncTask")
        task.state = TaskState.SCHEDULED
        self._queue.append(task)
        self._queue.sort(key=lambda item: (item.priority, item.task_id))

    def submit_many(self, tasks: Iterable[PantherAsyncTask]) -> None:
        for task in tasks:
            self.submit(task)

    @property
    def queued_count(self) -> int:
        return len(self._queue)

    async def run_all(self) -> List[PantherTaskResult]:
        semaphore = asyncio.Semaphore(self.policy.max_concurrency)
        ordered_tasks = list(self._queue)
        self._queue.clear()
        results: List[PantherTaskResult] = []

        async def run_one(task: PantherAsyncTask) -> PantherTaskResult:
            async with semaphore:
                return await task.run()

        if self.policy.fail_fast:
            for task in ordered_tasks:
                result = await run_one(task)
                results.append(result)
                if result.state in {TaskState.FAILED, TaskState.TIMED_OUT, TaskState.CANCELLED}:
                    break
            return results

        gathered = await asyncio.gather(*(run_one(task) for task in ordered_tasks))
        results.extend(gathered)
        return results
