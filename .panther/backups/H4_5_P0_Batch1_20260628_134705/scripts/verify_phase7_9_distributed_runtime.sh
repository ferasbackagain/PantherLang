#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 7.9 PRO Distributed Runtime Verification FAST"
echo "============================================================"

test -f runtime/distributed/distributed_runtime.py
echo "✅ structure tests passed"

python3 - <<'PY'
from runtime.distributed.distributed_runtime import DistributedRuntime
rt=DistributedRuntime()
rt.register("node-a")
rt.register("node-b")
assert rt.node_count()==2
msg=rt.broadcast("hello")
assert msg["node-a"]=="hello@node-a"
assert msg["node-b"]=="hello@node-b"
print("✅ distributed runtime tests passed")
PY

./panther run examples/phase7_distributed/distributed_demo.panther | grep -q "Phase 7.9 Distributed Runtime"
echo "✅ CLI bridge tests passed"

python3 -m py_compile runtime/distributed/distributed_runtime.py
echo "✅ python compile tests passed"

echo "✅ PantherLang Phase 7.9 Distributed Runtime verification complete."
