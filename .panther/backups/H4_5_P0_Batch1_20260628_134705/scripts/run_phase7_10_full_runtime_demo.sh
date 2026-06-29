#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 - <<'PY'
from runtime.final_integration.final_runtime import PantherFinalRuntime
rt = PantherFinalRuntime()
report = rt.run_full_integration()
assert report.ok is True
assert report.scheduler_tasks == 1
assert report.messages == 1
assert report.context_ok is True
assert report.plugins == 2
assert report.sandbox_ok is True
assert report.distributed_nodes == 2
print("runtime_full_integration=true")
print("scheduler=true")
print("multi_agent=true")
print("context_state=true")
print("plugins=true")
print("sandbox=true")
print("distributed=true")
PY

RUN_OUT="$(./panther run examples/phase7_final/final_runtime_demo.panther)"
echo "$RUN_OUT" | grep -q "Phase 7.10 Final Runtime Integration"
echo "$RUN_OUT" | grep -q "Phase 7 complete"

echo "demo=phase7.10-final-runtime"
echo "ok=true"
echo "panther_run=true"
echo "artifact_runs=true"
