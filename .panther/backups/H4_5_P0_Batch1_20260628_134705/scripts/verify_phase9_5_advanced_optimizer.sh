#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.5 Advanced Optimization Verification"
echo "============================================================"

test -f optimizer/passes/advanced_optimizer.py
test -f examples/phase9_advanced_optimizer/advanced_optimizer_demo.panther
echo "✅ structure tests passed"

python3 -m py_compile optimizer/passes/advanced_optimizer.py
echo "✅ python compile passed"

python3 optimizer/passes/advanced_optimizer.py >/tmp/p95_optimizer.json
grep -q '"phase": "9.5"' /tmp/p95_optimizer.json
grep -q 'constant_folding' /tmp/p95_optimizer.json
grep -q 'dead_code_elimination' /tmp/p95_optimizer.json
grep -q 'peephole' /tmp/p95_optimizer.json
grep -q '"op": "CONST"' /tmp/p95_optimizer.json
grep -q '"op": "MOV"' /tmp/p95_optimizer.json
echo "✅ advanced optimizer pass tests passed"

python3 - <<'PY'
from optimizer.passes.advanced_optimizer import AdvancedOptimizer

ir = [
    {"op": "BINARY", "operator": "+", "lhs": 10, "rhs": 20},
    {"op": "NOOP"},
    {"op": "MUL", "lhs": 1, "rhs": "value"},
    {"op": "PRINT", "value": "ok"},
]
result = AdvancedOptimizer().optimize(ir)
assert result["ok"] is True
assert result["before_nodes"] == 4
assert result["after_nodes"] == 3
ops = [x["op"] for x in result["optimized_ir"]]
assert "CONST" in ops
assert "MOV" in ops
assert "NOOP" not in ops
print("✅ python optimizer assertions passed")
PY

./panther build examples/phase9_advanced_optimizer/advanced_optimizer_demo.panther --release >/tmp/p95_build.json
grep -q '"ok": true' /tmp/p95_build.json
grep -q '"profile": "release"' /tmp/p95_build.json
test -f build/release/advanced_optimizer_demo.sh
bash build/release/advanced_optimizer_demo.sh | grep -q "Phase 9.5 Advanced Optimization Pipeline"
echo "✅ release build passed"

echo "✅ PantherLang Phase 9.5 Advanced Optimization Pipeline verification complete."
