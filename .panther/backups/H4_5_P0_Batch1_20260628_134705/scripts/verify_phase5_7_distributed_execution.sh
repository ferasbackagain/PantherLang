#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.7 PRO Verification"
echo "============================================================"

bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency_verify.log
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency_verify.log
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency_verify.log
bash scripts/verify_phase5_4_multi_agent_runtime.sh >/tmp/panther_phase5_4_dependency_verify.log
bash scripts/verify_phase5_5_natural_language_programming.sh >/tmp/panther_phase5_5_dependency_verify.log
bash scripts/verify_phase5_6_ai_optimizing_compiler.sh >/tmp/panther_phase5_6_dependency_verify.log

test -f architecture/DISTRIBUTED_EXECUTION.md
test -f language/distributed/core/distributed_manifest.json
test -f language/distributed/core/distributed_types.panther
test -f language/ai/distributed/distributed_ai_types.panther
test -f language/distributed/policies/default_distributed.policy.json
test -f language/distributed/schemas/distributed_task.schema.json
test -x language/distributed/runtime/distributed_runtime.py
test -f examples/distributed/phase5_7_distributed.panther
test -f examples/distributed/phase5_7_practical_expected.txt
test -x scripts/run_phase5_7_practical_demo.sh
test -f tests/phase5_7/test_distributed_runtime.py
test -f docs/phase5/PHASE_5_7_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/distributed/core/distributed_manifest.json").read_text())
assert m["phase"] == "5.7"
for dep in ["5.1","5.2","5.3","5.4","5.5","5.6"]:
    assert dep in m["depends_on"]
assert m["external_api_required"] is False
assert m["network_required"] is False
assert "task_distribution" in m["features"]
p = json.loads(Path("language/distributed/policies/default_distributed.policy.json").read_text())
assert p["allow_network"] is False
assert p["allow_remote_shell"] is False
assert p["require_capability_match"] is True
s = json.loads(Path("language/distributed/schemas/distributed_task.schema.json").read_text())
for key in ["id","required_capability","payload","status","audit"]:
    assert key in s["required"]
PY
echo "✅ schema tests passed"

DEMO_JSON="$(python3 language/distributed/runtime/distributed_runtime.py demo)"
echo "$DEMO_JSON" | grep -q '"phase": "5.7"'
echo "$DEMO_JSON" | grep -q '"ok": true'
echo "$DEMO_JSON" | grep -q '"scheduled_tasks": 3'
echo "$DEMO_JSON" | grep -q '"completed_tasks": 3'
echo "$DEMO_JSON" | grep -q '"failed_tasks": 0'
echo "$DEMO_JSON" | grep -q '"network_used": false'
echo "✅ runtime distributed tests passed"

python3 - "$DEMO_JSON" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
outputs = [r["output"] for r in data["results"]]
assert "PANTHER DISTRIBUTED EXECUTION" in outputs
assert "AI NATIVE RUNTIME" in outputs
assert 42 in outputs
for r in data["results"]:
    assert r["audit"]["external_api_used"] is False
    assert r["audit"]["network_used"] is False
    assert r["audit"]["deterministic"] is True
PY
echo "✅ scheduling/result tests passed"

STRESS_JSON="$(python3 language/distributed/runtime/distributed_runtime.py stress --count 50)"
echo "$STRESS_JSON" | grep -q '"ok": true'
echo "$STRESS_JSON" | grep -q '"scheduled_tasks": 50'
echo "$STRESS_JSON" | grep -q '"completed_tasks": 50'
echo "$STRESS_JSON" | grep -q '"failed_tasks": 0'
echo "✅ stress tests passed"

set +e
BAD_NODE="$(python3 language/distributed/runtime/distributed_runtime.py negative --case bad-node)"
BAD_NODE_CODE=$?
BAD_TASK="$(python3 language/distributed/runtime/distributed_runtime.py negative --case bad-task)"
BAD_TASK_CODE=$?
BAD_CAP="$(python3 language/distributed/runtime/distributed_runtime.py negative --case missing-capability)"
BAD_CAP_CODE=$?
set -e
if [ "$BAD_NODE_CODE" -ne 2 ] || [ "$BAD_TASK_CODE" -ne 2 ] || [ "$BAD_CAP_CODE" -ne 2 ]; then
  echo "[verify_phase5.7][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_NODE" | grep -q 'Node id cannot be empty'
echo "$BAD_TASK" | grep -q 'Task id cannot be empty'
echo "$BAD_CAP" | grep -q 'Missing required node capability'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase5_7_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=distributed-execution'
echo "$PRACTICAL_OUT" | grep -q 'ok=true'
echo "$PRACTICAL_OUT" | grep -q 'completed_tasks=3'
echo "$PRACTICAL_OUT" | grep -q 'contains=42'
echo "✅ practical distributed execution demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_7 >/tmp/panther_phase5_7_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/distributed/runtime/distributed_runtime.py
  echo "✅ python compile test passed"
fi

echo "✅ PantherLang Phase 5.7 Distributed Execution verification complete."
