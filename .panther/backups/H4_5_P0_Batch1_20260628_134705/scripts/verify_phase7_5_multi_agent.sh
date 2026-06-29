#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.5 PRO Multi-Agent Verification FAST"
echo "============================================================"

test -f runtime/multi_agent/bus.py
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.multi_agent.bus import AgentBus,Agent
bus=AgentBus()
a=Agent("research",bus)
b=Agent("report",bus)
a.send("report","scan complete")
msgs=bus.inbox("report")
assert len(msgs)==1
assert msgs[0].payload=="scan complete"
print("✅ agent communication tests passed")
PY

./panther run examples/phase7_multi_agent/agents_demo.panther | grep -q "Phase 7.5 Multi-Agent Communication"
echo "✅ CLI bridge tests passed"

python3 -m py_compile runtime/multi_agent/bus.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.5 Multi-Agent Communication verification complete."
