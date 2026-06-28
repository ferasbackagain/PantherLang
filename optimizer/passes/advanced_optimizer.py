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
