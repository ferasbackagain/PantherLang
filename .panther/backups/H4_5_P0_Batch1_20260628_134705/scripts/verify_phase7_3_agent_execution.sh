#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.3 PRO Agent Execution Verification FAST"
echo "============================================================"

test -f runtime/agents/agent.py
test -f runtime/agents/agent_context.py
test -f runtime/agents/agent_registry.py
test -f runtime/agents/agent_executor.py
test -f runtime/agents/agent_api.py
test -f examples/phase7_agents/agent_demo.panther
test -x scripts/run_phase7_3_practical_demo.sh
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.agents.agent import PantherAgent
agent = PantherAgent(name="VerifyAgent", role="verifier", goal="phase7.3")
result = agent.execute("verify-agent")
assert result["ok"] is True
assert result["agent"] == "VerifyAgent"
assert result["context"]["memory"]["VerifyAgent.last_instruction"]["value"] == "verify-agent"
print("✅ agent execution tests passed")
PY

python3 runtime/agents/agent_api.py demo | grep -q '"ok": true'
echo "✅ agent API tests passed"

OUT="/tmp/panther_phase7_3_verify_$$.sh"
./panther compile examples/phase7_agents/agent_demo.panther --out "$OUT" | grep -q '"ok": true'
bash "$OUT" | grep -q 'Phase 7.3 Agent Execution Engine'
rm -f "$OUT"
echo "✅ compiler bridge tests passed"

bash scripts/run_phase7_3_practical_demo.sh | grep -q 'demo=phase7.3-agent-execution-engine'
echo "✅ practical agent demo passed"

python3 -m py_compile runtime/agents/*.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.3 Agent Execution Engine verification complete."
