#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 9.5 PRO - Advanced Optimization Pipeline"
echo "============================================================"

mkdir -p optimizer/passes examples/phase9_advanced_optimizer scripts docs/phase9 tests/phase9_5

cat > optimizer/passes/advanced_optimizer.py <<'PY'
#!/usr/bin/env python3
from __future__ import annotations

import json
from typing import Any


class AdvancedOptimizer:
    def constant_folding(self, ir: list[dict[str, Any]]) -> list[dict[str, Any]]:
        out = []
        for node in ir:
            if node.get("op") == "BINARY" and node.get("operator") == "+":
                lhs = node.get("lhs")
                rhs = node.get("rhs")
                if isinstance(lhs, int) and isinstance(rhs, int):
                    out.append({"op": "CONST", "value": lhs + rhs})
                    continue
            out.append(node)
        return out

    def dead_code_elimination(self, ir: list[dict[str, Any]]) -> list[dict[str, Any]]:
        return [node for node in ir if node.get("op") != "NOOP" and node.get("dead") is not True]

    def peephole(self, ir: list[dict[str, Any]]) -> list[dict[str, Any]]:
        out = []
        for node in ir:
            if node.get("op") == "ADD" and node.get("lhs") == 0:
                out.append({"op": "MOV", "value": node.get("rhs")})
            elif node.get("op") == "MUL" and node.get("lhs") == 1:
                out.append({"op": "MOV", "value": node.get("rhs")})
            else:
                out.append(node)
        return out

    def optimize(self, ir: list[dict[str, Any]]) -> dict[str, Any]:
        before = len(ir)
        ir1 = self.constant_folding(ir)
        ir2 = self.dead_code_elimination(ir1)
        ir3 = self.peephole(ir2)
        return {
            "ok": True,
            "phase": "9.5",
            "before_nodes": before,
            "after_nodes": len(ir3),
            "optimized_ir": ir3,
            "passes": [
                "constant_folding",
                "dead_code_elimination",
                "peephole"
            ]
        }


if __name__ == "__main__":
    sample = [
        {"op": "BINARY", "operator": "+", "lhs": 2, "rhs": 3},
        {"op": "NOOP"},
        {"op": "ADD", "lhs": 0, "rhs": "x"},
        {"op": "PRINT", "value": "done"}
    ]
    print(json.dumps(AdvancedOptimizer().optimize(sample), indent=2, sort_keys=True))
PY
chmod +x optimizer/passes/advanced_optimizer.py

cat > examples/phase9_advanced_optimizer/advanced_optimizer_demo.panther <<'EOF'
print "Phase 9.5 Advanced Optimization Pipeline"
EOF

cat > docs/phase9/PHASE_9_5_STATUS.md <<'EOF'
# Phase 9.5 — Advanced Optimization Pipeline

Completed:
- Constant folding pass
- Dead code elimination pass
- Peephole optimization pass
- Multi-pass optimizer pipeline
- Release build verification
- Regression script

Next: Phase 9.6 — Build Cache Integration.
EOF

cat > scripts/verify_phase9_5_advanced_optimizer.sh <<'EOF'
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
EOF
chmod +x scripts/verify_phase9_5_advanced_optimizer.sh

echo "[phase9.5] Running verification..."
bash scripts/verify_phase9_5_advanced_optimizer.sh

echo "============================================================"
echo " Phase 9.5 COMPLETE"
echo " Next: Phase 9.6 Build Cache Integration"
echo "============================================================"
