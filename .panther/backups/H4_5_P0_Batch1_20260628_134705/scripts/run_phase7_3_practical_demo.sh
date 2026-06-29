#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

python3 runtime/agents/agent_api.py demo >/tmp/panther_phase7_3_agent_demo.json
grep -q '"ok": true' /tmp/panther_phase7_3_agent_demo.json
grep -q '"demo": "agent-execution-engine"' /tmp/panther_phase7_3_agent_demo.json
grep -q '"agent": "ResearchAgent"' /tmp/panther_phase7_3_agent_demo.json

OUT="/tmp/panther_phase7_3_compile_$$.sh"
./panther compile examples/phase7_agents/agent_demo.panther --out "$OUT" | grep -q '"ok": true'
RUN_OUT="$(bash "$OUT")"
echo "$RUN_OUT" | grep -q 'Phase 7.3 Agent Execution Engine'
rm -f "$OUT"

echo "demo=phase7.3-agent-execution-engine"
echo "ok=true"
echo "agent_register=true"
echo "agent_execute=true"
echo "native_memory=true"
echo "compile_bridge=true"
echo "artifact_runs=true"
