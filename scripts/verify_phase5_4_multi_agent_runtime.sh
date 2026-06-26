#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.4 PRO Verification"
echo "============================================================"

bash scripts/verify_phase5_1_ai_native_core.sh >/tmp/panther_phase5_1_dependency_verify.log
bash scripts/verify_phase5_2_intelligent_type_system.sh >/tmp/panther_phase5_2_dependency_verify.log
bash scripts/verify_phase5_3_memory_context_engine.sh >/tmp/panther_phase5_3_dependency_verify.log

test -f architecture/MULTI_AGENT_RUNTIME.md
test -f language/agents/core/agent_manifest.json
test -f language/agents/core/agent_types.panther
test -f language/ai/agents/agent_workflow_types.panther
test -f language/agents/policies/default_agent.policy.json
test -f language/agents/schemas/agent_message.schema.json
test -x language/agents/runtime/agent_runtime.py
test -f examples/agents/phase5_4_multi_agent.panther
test -f examples/agents/phase5_4_practical_expected.txt
test -x scripts/run_phase5_4_practical_demo.sh
test -f tests/phase5_4/test_agent_runtime.py
test -f docs/phase5/PHASE_5_4_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path

manifest = json.loads(Path("language/agents/core/agent_manifest.json").read_text())
assert manifest["phase"] == "5.4"
for dep in ["5.1", "5.2", "5.3"]:
    assert dep in manifest["depends_on"]
assert manifest["external_api_required"] is False
assert "message_bus" in manifest["features"]
assert "stress_tests" in manifest["features"]

policy = json.loads(Path("language/agents/policies/default_agent.policy.json").read_text())
assert policy["allow_network"] is False
assert policy["allow_secret_access"] is False
assert policy["audit_required"] is True
assert "message" in policy["allowed_permissions"]

schema = json.loads(Path("language/agents/schemas/agent_message.schema.json").read_text())
for key in ["id", "from_agent", "to_agent", "kind", "payload", "created_at", "audit"]:
    assert key in schema["required"]
PY
echo "✅ schema tests passed"

DEMO_JSON="$(python3 language/agents/runtime/agent_runtime.py demo)"
echo "$DEMO_JSON" | grep -q '"phase": "5.4"'
echo "$DEMO_JSON" | grep -q '"workflow": "planner-coder-reviewer"'
echo "$DEMO_JSON" | grep -q '"ok": true'
echo "$DEMO_JSON" | grep -q '"agents_executed": 3'
echo "$DEMO_JSON" | grep -q '"messages_exchanged": 3'
echo "$DEMO_JSON" | grep -q '"security_violations": 0'
echo "$DEMO_JSON" | grep -q '"external_api_used": false'
echo "✅ runtime demo tests passed"

python3 - "$DEMO_JSON" <<'PY'
import json
import sys
data = json.loads(sys.argv[1])
messages = data["messages"]
assert messages[0]["from_agent"] == "planner"
assert messages[0]["to_agent"] == "coder"
assert messages[1]["from_agent"] == "coder"
assert messages[1]["to_agent"] == "reviewer"
assert messages[2]["from_agent"] == "reviewer"
assert messages[2]["to_agent"] == "planner"
for msg in messages:
    assert msg["audit"]["external_api_used"] is False
    assert msg["audit"]["deterministic"] is True
PY
echo "✅ message passing tests passed"

STRESS_JSON="$(python3 language/agents/runtime/agent_runtime.py stress --count 25)"
echo "$STRESS_JSON" | grep -q '"ok": true'
echo "$STRESS_JSON" | grep -q '"stress_messages": 25'
echo "$STRESS_JSON" | grep -q '"messages_exchanged": 25'
echo "$STRESS_JSON" | grep -q '"security_violations": 0'
echo "✅ stress tests passed"

set +e
BAD_UNREG="$(python3 language/agents/runtime/agent_runtime.py negative --case unregistered)"
BAD_UNREG_CODE=$?
BAD_PERM="$(python3 language/agents/runtime/agent_runtime.py negative --case permission)"
BAD_PERM_CODE=$?
BAD_ROLE="$(python3 language/agents/runtime/agent_runtime.py negative --case bad-role)"
BAD_ROLE_CODE=$?
set -e

if [ "$BAD_UNREG_CODE" -ne 2 ] || [ "$BAD_PERM_CODE" -ne 2 ] || [ "$BAD_ROLE_CODE" -ne 2 ]; then
  echo "[verify_phase5.4][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_UNREG" | grep -q 'Unregistered agent'
echo "$BAD_PERM" | grep -q 'lacks permission'
echo "$BAD_ROLE" | grep -q 'Invalid role'
echo "✅ security/negative tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase5_4_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'workflow=planner-coder-reviewer'
echo "$PRACTICAL_OUT" | grep -q 'ok=true'
echo "$PRACTICAL_OUT" | grep -q 'agents_executed=3'
echo "$PRACTICAL_OUT" | grep -q 'messages_exchanged=3'
echo "$PRACTICAL_OUT" | grep -q 'security_violations=0'
echo "$PRACTICAL_OUT" | grep -q 'contains=Reviewer approved PantherLang multi-agent workflow'
echo "✅ practical PantherLang multi-agent demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_4 >/tmp/panther_phase5_4_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/agents/runtime/agent_runtime.py
  echo "✅ python compile test passed"
fi

echo "✅ PantherLang Phase 5.4 Multi-Agent Runtime verification complete."
