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
