#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.8 PRO Secure Sandbox Verification FAST"
echo "============================================================"

test -f runtime/sandbox/sandbox.py
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.sandbox.sandbox import SandboxRuntime
rt=SandboxRuntime()
r=rt.execute("agent.run")
assert r["ok"]
assert r["sandbox"]=="secure"
assert r["network"] is False
assert r["filesystem"] is False
print("✅ sandbox runtime tests passed")
PY

./panther run examples/phase7_sandbox/sandbox_demo.panther | grep -q "Phase 7.8 Secure Sandbox Runtime"
echo "✅ CLI bridge tests passed"

python3 -m py_compile runtime/sandbox/sandbox.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.8 Secure Sandbox Runtime verification complete."
