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
