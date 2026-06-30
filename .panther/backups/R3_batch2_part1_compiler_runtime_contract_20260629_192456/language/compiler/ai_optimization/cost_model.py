from __future__ import annotations
from dataclasses import dataclass, asdict
from typing import Dict
from .ir import OptimizationUnit, OptimizationNode
@dataclass(slots=True)
class CostEstimate:
    unit_name: str; node_count: int; estimated_runtime_cost: float; estimated_memory_cost: float; ai_complexity_score: float
    def to_dict(self) -> Dict[str, object]: return asdict(self)
class AICostModel:
    WEIGHTS={"literal":0.1,"constant":0.1,"expr":0.8,"call":1.5,"agent_call":3.5,"workflow":4.0,"dead":0.2}
    def estimate(self, unit: OptimizationUnit) -> CostEstimate:
        unit.validate(); nodes=[]
        def walk(n: OptimizationNode):
            nodes.append(n)
            for c in n.children: walk(c)
        for n in unit.nodes: walk(n)
        runtime=sum(self.WEIGHTS.get(n.kind,1.0) for n in nodes)
        memory=sum(0.5 + len(n.children)*0.25 for n in nodes)
        ai=sum(1.0 for n in nodes if n.kind in {"agent_call","workflow"})*2.0 + runtime*0.10
        return CostEstimate(unit.name,len(nodes),round(runtime,4),round(memory,4),round(ai,4))
