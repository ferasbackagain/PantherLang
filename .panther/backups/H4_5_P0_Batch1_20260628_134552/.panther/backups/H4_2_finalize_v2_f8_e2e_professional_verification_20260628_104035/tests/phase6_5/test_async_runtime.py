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
