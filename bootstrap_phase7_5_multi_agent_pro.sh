#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 7.5 PRO - Multi-Agent Communication"
echo "============================================================"

ROOT="$(pwd)"
mkdir -p runtime/multi_agent examples/phase7_multi_agent tests/phase7_5 scripts

cat > runtime/multi_agent/bus.py <<'PY'
from dataclasses import dataclass

@dataclass
class Message:
    sender:str
    receiver:str
    payload:str

class AgentBus:
    def __init__(self):
        self.messages=[]

    def send(self,sender,receiver,payload):
        self.messages.append(Message(sender,receiver,payload))

    def inbox(self,receiver):
        return [m for m in self.messages if m.receiver==receiver]

class Agent:
    def __init__(self,name,bus):
        self.name=name
        self.bus=bus

    def send(self,to,msg):
        self.bus.send(self.name,to,msg)
PY

cat > examples/phase7_multi_agent/agents_demo.panther <<'EOF'
module panther.multiagent

print "Phase 7.5 Multi-Agent Communication"
EOF

cat > scripts/verify_phase7_5_multi_agent.sh <<'EOF'
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
EOF

chmod +x scripts/verify_phase7_5_multi_agent.sh

echo "[phase7.5] Running verification..."
bash scripts/verify_phase7_5_multi_agent.sh

echo "============================================================"
echo " Phase 7.5 COMPLETE"
echo " Next: Phase 7.6 Context & State Engine"
echo "============================================================"
