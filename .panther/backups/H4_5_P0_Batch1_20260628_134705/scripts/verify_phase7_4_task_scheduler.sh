#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.4 PRO Task Scheduler Verification FAST"
echo "============================================================"

test -f runtime/task_scheduler/scheduler.py
python3 - <<'PY'
from runtime.task_scheduler.scheduler import Scheduler
s=Scheduler()
s.add("scan","security")
r=s.run()
assert r==["executed:scan:security"]
print("✅ scheduler tests passed")
PY

./panther run examples/phase7_scheduler/task_demo.panther | grep -q "Phase 7.4 Task Scheduler"
echo "✅ CLI bridge tests passed"

python3 -m py_compile runtime/task_scheduler/scheduler.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.4 Task Scheduler verification complete."
