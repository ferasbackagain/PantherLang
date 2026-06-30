from __future__ import annotations
from dataclasses import dataclass, field
from typing import List, Tuple
from .ir import OptimizationNode, OptimizationUnit
@dataclass(slots=True)
class OptimizationPass:
    name: str
    def run(self, unit: OptimizationUnit) -> Tuple[OptimizationUnit, List[str]]: raise NotImplementedError
class ConstantFoldingPass(OptimizationPass):
    def __init__(self) -> None: super().__init__("constant_folding")
    def run(self, unit: OptimizationUnit) -> Tuple[OptimizationUnit, List[str]]:
        changes=[]
        def fold(n: OptimizationNode):
            for c in n.children: fold(c)
            if n.kind=="expr" and n.value in {"add","+"} and len(n.children)==2:
                a,b=n.children
                if a.kind in {"literal","constant"} and b.kind in {"literal","constant"} and isinstance(a.value,(int,float)) and isinstance(b.value,(int,float)):
                    n.kind="constant"; n.value=a.value+b.value; n.children=[]; n.metadata["folded_by"]=self.name; changes.append("folded numeric addition")
        for node in unit.nodes: fold(node)
        return unit, changes
class DeadCodeEliminationPass(OptimizationPass):
    def __init__(self) -> None: super().__init__("dead_code_elimination")
    def run(self, unit: OptimizationUnit) -> Tuple[OptimizationUnit, List[str]]:
        before=len(unit.nodes); unit.nodes=[n for n in unit.nodes if not (n.kind=="dead" or n.metadata.get("reachable") is False)]
        removed=before-len(unit.nodes); return unit, ([f"removed {removed} unreachable node(s)"] if removed else [])
class AgentHintPass(OptimizationPass):
    def __init__(self) -> None: super().__init__("agent_hint_enrichment")
    def run(self, unit: OptimizationUnit) -> Tuple[OptimizationUnit, List[str]]:
        changes=[]
        def visit(n: OptimizationNode):
            if n.kind in {"agent_call","workflow"}:
                n.metadata.setdefault("ai_optimization_hint","batch_tools_cache_memory_and_limit_context")
                n.metadata.setdefault("safety","preserve_permissions_and_audit_trail")
                changes.append(f"annotated {n.kind}")
            for c in n.children: visit(c)
        for node in unit.nodes: visit(node)
        return unit, changes
@dataclass(slots=True)
class PassManager:
    passes: List[OptimizationPass] = field(default_factory=lambda: [ConstantFoldingPass(), DeadCodeEliminationPass(), AgentHintPass()])
    def run(self, unit: OptimizationUnit) -> Tuple[OptimizationUnit, List[str]]:
        diagnostics=[]; unit.validate()
        for opt_pass in self.passes:
            unit, changes=opt_pass.run(unit)
            diagnostics.extend([f"{opt_pass.name}: {c}" for c in changes] or [f"{opt_pass.name}: no changes"])
            unit.validate()
        return unit, diagnostics
