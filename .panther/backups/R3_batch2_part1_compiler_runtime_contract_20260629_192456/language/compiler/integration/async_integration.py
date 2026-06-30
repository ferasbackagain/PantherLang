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
