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
