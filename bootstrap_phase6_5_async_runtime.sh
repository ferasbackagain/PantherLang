#!/usr/bin/env bash
set -euo pipefail

PHASE="6.5"
PHASE_NAME="Async Runtime"
ROOT="$(pwd)"
BACKUP_DIR=".phase_backups/phase6_5_async_runtime_$(date +%Y%m%d_%H%M%S)"

banner() {
  echo ""
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

require_project_root() {
  if [ ! -d "language" ] || [ ! -d "scripts" ] || [ ! -d "tests" ]; then
    echo "ERROR: run this script from the PantherLang project root." >&2
    echo "Expected directories: language/, scripts/, tests/" >&2
    exit 1
  fi
}

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
}

backup_existing() {
  mkdir -p "$BACKUP_DIR"
  for path in \
    "language/runtime/async_runtime" \
    "language/compiler/integration/async_integration.py" \
    "tests/phase6_5" \
    "scripts/run_phase6_5_practical_demo.sh" \
    "scripts/verify_phase6_5_async_runtime.sh" \
    "docs/phase6/PHASE_6_5_ASYNC_RUNTIME.md"; do
    if [ -e "$path" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$path")"
      cp -a "$path" "$BACKUP_DIR/$path"
    fi
  done
}

update_changelog() {
  local marker="Phase 6.5 - Async Runtime"
  if [ -f CHANGELOG.md ] && ! grep -q "$marker" CHANGELOG.md; then
    cat >> CHANGELOG.md <<'EOF_CHANGELOG'

## Phase 6.5 - Async Runtime

Added a production-oriented async runtime foundation for PantherLang:

- Cooperative task abstraction and lifecycle states.
- Priority-aware async scheduler.
- Timeout-aware execution support.
- Cancellation and failure propagation.
- Runtime metrics and JSON report generation.
- Compiler integration adapter for async execution plans.
- Professional verification, practical demo, negative tests, and stress tests.

GitHub push remains postponed until Phase 6.10 full regression.
EOF_CHANGELOG
  fi
}

write_runtime_files() {
  write_file "language/runtime/async_runtime/__init__.py" <<'PYEOF'
"""PantherLang Phase 6.5 async runtime package."""

from .task import PantherAsyncTask, PantherTaskResult, TaskState
from .scheduler import PantherAsyncScheduler, SchedulerPolicy
from .runtime import PantherAsyncRuntime, PantherAsyncRuntimeError

__all__ = [
    "PantherAsyncTask",
    "PantherTaskResult",
    "TaskState",
    "PantherAsyncScheduler",
    "SchedulerPolicy",
    "PantherAsyncRuntime",
    "PantherAsyncRuntimeError",
]
PYEOF

  write_file "language/runtime/async_runtime/task.py" <<'PYEOF'
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
PYEOF

  write_file "language/runtime/async_runtime/scheduler.py" <<'PYEOF'
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
PYEOF

  write_file "language/runtime/async_runtime/runtime.py" <<'PYEOF'
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
PYEOF
}

write_compiler_integration() {
  write_file "language/compiler/integration/async_integration.py" <<'PYEOF'
"""Compiler integration adapter for Phase 6.5 async runtime.

This adapter is deliberately small and stable. It gives the compiler pipeline a
structured execution-plan object that can later be populated from AST/IR async
nodes in Phase 6.10 without coupling earlier phases to a specific parser shape.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable, Iterable, List

from language.runtime.async_runtime import PantherAsyncRuntime


@dataclass(slots=True)
class AsyncExecutionUnit:
    name: str
    operation: Callable[..., Any]
    args: tuple[Any, ...] = field(default_factory=tuple)
    kwargs: dict[str, Any] = field(default_factory=dict)
    priority: int = 100
    timeout_seconds: float | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(slots=True)
class AsyncExecutionPlan:
    units: List[AsyncExecutionUnit] = field(default_factory=list)
    max_concurrency: int = 8

    def add_unit(self, unit: AsyncExecutionUnit) -> None:
        if not isinstance(unit, AsyncExecutionUnit):
            raise TypeError("unit must be an AsyncExecutionUnit")
        self.units.append(unit)


class AsyncCompilerIntegration:
    def build_runtime(self, plan: AsyncExecutionPlan) -> PantherAsyncRuntime:
        if not isinstance(plan, AsyncExecutionPlan):
            raise TypeError("plan must be an AsyncExecutionPlan")
        runtime = PantherAsyncRuntime(max_concurrency=plan.max_concurrency)
        for unit in plan.units:
            runtime.submit(
                runtime.create_task(
                    unit.name,
                    unit.operation,
                    *unit.args,
                    priority=unit.priority,
                    timeout_seconds=unit.timeout_seconds,
                    metadata=unit.metadata,
                    **unit.kwargs,
                )
            )
        return runtime

    def execute_plan(self, plan: AsyncExecutionPlan) -> dict[str, Any]:
        runtime = self.build_runtime(plan)
        runtime.run()
        return runtime.report()

    @staticmethod
    def plan_from_units(units: Iterable[AsyncExecutionUnit], *, max_concurrency: int = 8) -> AsyncExecutionPlan:
        plan = AsyncExecutionPlan(max_concurrency=max_concurrency)
        for unit in units:
            plan.add_unit(unit)
        return plan
PYEOF
}

write_tests() {
  write_file "tests/phase6_5/test_async_runtime.py" <<'PYEOF'
import asyncio
import json
from pathlib import Path

import pytest

from language.compiler.integration.async_integration import (
    AsyncCompilerIntegration,
    AsyncExecutionPlan,
    AsyncExecutionUnit,
)
from language.runtime.async_runtime import PantherAsyncRuntime, PantherAsyncTask, TaskState


async def async_double(value):
    await asyncio.sleep(0)
    return value * 2


def sync_add(a, b):
    return a + b


def test_positive_sync_and_async_tasks(tmp_path):
    runtime = PantherAsyncRuntime(max_concurrency=2)
    runtime.submit(runtime.create_task("sync-add", sync_add, 2, 3, priority=20))
    runtime.submit(runtime.create_task("async-double", async_double, 7, priority=10))

    results = runtime.run()
    values = {item.task_id: item.value for item in results}

    assert values == {"async-double": 14, "sync-add": 5}
    assert runtime.metrics()["states"]["completed"] == 2

    report_path = runtime.write_report(tmp_path / "async-report.json")
    data = json.loads(Path(report_path).read_text(encoding="utf-8"))
    assert data["metrics"]["phase"] == "6.5"
    assert len(data["results"]) == 2


def test_priority_order_is_deterministic():
    runtime = PantherAsyncRuntime(max_concurrency=1)
    runtime.submit(runtime.create_task("low", sync_add, 1, 1, priority=50))
    runtime.submit(runtime.create_task("high", sync_add, 1, 2, priority=1))
    results = runtime.run()
    assert [item.task_id for item in results] == ["high", "low"]


def test_negative_invalid_task_definition():
    with pytest.raises(ValueError):
        PantherAsyncTask(task_id="", operation=sync_add)
    with pytest.raises(ValueError):
        PantherAsyncTask(task_id="bad-priority", operation=sync_add, priority=-1)
    with pytest.raises(ValueError):
        PantherAsyncRuntime(max_concurrency=0)


def test_negative_failure_is_reported_not_hidden():
    def explode():
        raise RuntimeError("boom")

    runtime = PantherAsyncRuntime(max_concurrency=1)
    runtime.submit(runtime.create_task("explode", explode))
    [result] = runtime.run()
    assert result.state == TaskState.FAILED
    assert "RuntimeError" in result.error


def test_timeout_state_is_reported():
    async def too_slow():
        await asyncio.sleep(0.05)
        return "late"

    runtime = PantherAsyncRuntime(max_concurrency=1)
    runtime.submit(runtime.create_task("too-slow", too_slow, timeout_seconds=0.001))
    [result] = runtime.run()
    assert result.state == TaskState.TIMED_OUT


def test_compiler_async_integration_plan():
    plan = AsyncExecutionPlan(max_concurrency=2)
    plan.add_unit(AsyncExecutionUnit("a", sync_add, args=(4, 5)))
    plan.add_unit(AsyncExecutionUnit("b", async_double, args=(6,)))

    report = AsyncCompilerIntegration().execute_plan(plan)
    values = {item["task_id"]: item["value"] for item in report["results"]}
    assert values == {"a": 9, "b": 12}
    assert report["metrics"]["tasks_total"] == 2


def test_stress_many_tasks():
    runtime = PantherAsyncRuntime(max_concurrency=16)
    for index in range(250):
        runtime.submit(runtime.create_task(f"task-{index:03d}", sync_add, index, 1, priority=index % 7))
    results = runtime.run()
    assert len(results) == 250
    assert all(item.state == TaskState.COMPLETED for item in results)
    assert sum(item.value for item in results) == sum(range(1, 251))
PYEOF
}

write_demo_and_verify() {
  write_file "scripts/run_phase6_5_practical_demo.sh" <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PYEOF'
import asyncio
from language.compiler.integration.async_integration import AsyncCompilerIntegration, AsyncExecutionUnit

async def fetch_signal(name, value):
    await asyncio.sleep(0)
    return {"signal": name, "score": value}

def normalize(value):
    return value.upper()

units = [
    AsyncExecutionUnit("normalize-module", normalize, args=("panther async runtime",), priority=5),
    AsyncExecutionUnit("ai-signal", fetch_signal, args=("compiler-ready", 98), priority=1),
]
plan = AsyncCompilerIntegration.plan_from_units(units, max_concurrency=2)
report = AsyncCompilerIntegration().execute_plan(plan)
print("Phase 6.5 demo ok:", report["metrics"]["states"]["completed"] == 2)
print("Tasks executed:", report["metrics"]["tasks_total"])
print("Completed:", report["metrics"]["states"]["completed"])
PYEOF
SHEOF
  chmod +x "scripts/run_phase6_5_practical_demo.sh"

  write_file "scripts/verify_phase6_5_async_runtime.sh" <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
mkdir -p build/reports

echo "== PantherLang Phase 6.5 Professional Verification =="
python3 - <<'PYEOF'
import importlib
modules = [
    "language.runtime.async_runtime",
    "language.runtime.async_runtime.task",
    "language.runtime.async_runtime.scheduler",
    "language.runtime.async_runtime.runtime",
    "language.compiler.integration.async_integration",
]
for module in modules:
    importlib.import_module(module)
print("Imports/positive smoke: PASS")
PYEOF

if python3 -m pytest tests/phase6_5 -q; then
  echo "Pytest: PASS"
else
  echo "Pytest: FAIL" >&2
  exit 1
fi

bash scripts/run_phase6_5_practical_demo.sh

python3 - <<'PYEOF'
import json
from language.runtime.async_runtime import PantherAsyncRuntime, TaskState

def fail():
    raise ValueError("intentional negative test")

runtime = PantherAsyncRuntime(max_concurrency=1)
runtime.submit(runtime.create_task("negative-failure", fail))
runtime.run()
report = runtime.report()
assert report["results"][0]["state"] == TaskState.FAILED.value
print("Negative tests: PASS")
PYEOF

python3 - <<'PYEOF'
from language.runtime.async_runtime import PantherAsyncRuntime, TaskState

def add(a, b):
    return a + b

runtime = PantherAsyncRuntime(max_concurrency=32)
for i in range(500):
    runtime.submit(runtime.create_task(f"stress-{i}", add, i, 1, priority=i % 11))
results = runtime.run()
assert len(results) == 500
assert all(r.state == TaskState.COMPLETED for r in results)
runtime.write_report("build/reports/phase6_5_last_async_report.json")
print("Stress test: PASS")
PYEOF

python3 - <<'PYEOF'
import json
from pathlib import Path
summary = {
    "phase": "6.5",
    "name": "Async Runtime",
    "status": "PASS",
    "reports": [
        "build/reports/phase6_5_verification_summary.json",
        "build/reports/phase6_5_last_async_report.json",
    ],
}
Path("build/reports").mkdir(parents=True, exist_ok=True)
Path("build/reports/phase6_5_verification_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
print("Phase 6.5 verification completed successfully.")
PYEOF
SHEOF
  chmod +x "scripts/verify_phase6_5_async_runtime.sh"
}

write_docs() {
  write_file "docs/phase6/PHASE_6_5_ASYNC_RUNTIME.md" <<'MDEOF'
# PantherLang Phase 6.5 — Async Runtime

## Status

Implemented as an incremental production-compiler milestone.

## Purpose

Phase 6.5 introduces a PantherLang async runtime foundation that supports cooperative execution, deterministic scheduling, failure reporting, timeout handling, and compiler integration through explicit async execution plans.

## Added Components

- `language/runtime/async_runtime/task.py`
- `language/runtime/async_runtime/scheduler.py`
- `language/runtime/async_runtime/runtime.py`
- `language/compiler/integration/async_integration.py`
- `tests/phase6_5/test_async_runtime.py`
- `scripts/run_phase6_5_practical_demo.sh`
- `scripts/verify_phase6_5_async_runtime.sh`

## Verification Coverage

- Positive imports and smoke tests.
- Sync and async task execution.
- Priority ordering.
- Timeout reporting.
- Failure reporting.
- Compiler async execution-plan integration.
- Stress execution with hundreds of tasks.
- JSON report generation under `build/reports`.

## GitHub Policy

GitHub push remains postponed until Phase 6.10 full regression.
MDEOF
}

run_verification() {
  banner "Running Phase 6.5 verification"
  bash scripts/verify_phase6_5_async_runtime.sh
}

main() {
  banner "PantherLang Phase 6.5 - Async Runtime"
  require_project_root
  backup_existing
  mkdir -p language/runtime/async_runtime language/compiler/integration tests/phase6_5 scripts docs/phase6 build/reports
  write_runtime_files
  write_compiler_integration
  write_tests
  write_demo_and_verify
  write_docs
  update_changelog
  run_verification
  banner "PantherLang Phase 6.5 bootstrap finished"
  echo "Reports: build/reports/phase6_5_verification_summary.json and build/reports/phase6_5_last_async_report.json"
  echo "GitHub push remains postponed until Phase 6.10 full regression."
}

main "$@"
