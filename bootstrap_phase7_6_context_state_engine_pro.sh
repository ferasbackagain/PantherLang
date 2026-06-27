#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 7.6 PRO - Context & State Engine"
echo "============================================================"

ROOT="$(pwd)"
mkdir -p runtime/context_state examples/phase7_context tests/phase7_6 scripts

cat > runtime/context_state/state_engine.py <<'PY'
from dataclasses import dataclass, field

@dataclass
class RuntimeState:
    values: dict = field(default_factory=dict)

    def set(self,key,value):
        self.values[key]=value

    def get(self,key,default=None):
        return self.values.get(key,default)

class ContextEngine:
    def __init__(self):
        self.global_state=RuntimeState()
        self.agent_states={}

    def context(self,agent):
        if agent not in self.agent_states:
            self.agent_states[agent]=RuntimeState()
        return self.agent_states[agent]

    def sync(self,agent,key):
        self.context(agent).set(key,self.global_state.get(key))
PY

cat > examples/phase7_context/context_demo.panther <<'EOF'
module panther.context

print "Phase 7.6 Context & State Engine"
EOF

cat > scripts/verify_phase7_6_context_state.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.6 PRO Context Verification FAST"
echo "============================================================"

test -f runtime/context_state/state_engine.py
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.context_state.state_engine import ContextEngine
ctx=ContextEngine()
ctx.global_state.set("mission","red-team")
ctx.sync("agent1","mission")
assert ctx.context("agent1").get("mission")=="red-team"
ctx.context("agent1").set("status","running")
assert ctx.context("agent1").get("status")=="running"
print("✅ context/state tests passed")
PY

./panther run examples/phase7_context/context_demo.panther | grep -q "Phase 7.6 Context & State Engine"
echo "✅ CLI bridge tests passed"

python3 -m py_compile runtime/context_state/state_engine.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.6 Context & State Engine verification complete."
EOF

chmod +x scripts/verify_phase7_6_context_state.sh

echo "[phase7.6] Running verification..."
bash scripts/verify_phase7_6_context_state.sh

echo "============================================================"
echo " Phase 7.6 COMPLETE"
echo " Next: Phase 7.7 Plugin & Extension System"
echo "============================================================"
