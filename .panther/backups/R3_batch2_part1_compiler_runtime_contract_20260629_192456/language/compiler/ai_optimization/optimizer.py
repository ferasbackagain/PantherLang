from __future__ import annotations
import json, hashlib
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Dict, List
from .cost_model import AICostModel
from .ir import OptimizationNode, OptimizationUnit
from .passes import PassManager
@dataclass(slots=True)
class OptimizationResult:
    unit_name: str; before_cost: Dict[str, object]; after_cost: Dict[str, object]; optimized_unit: Dict[str, object]; diagnostics: List[str]; report_path: str; sha256: str; success: bool=True
    def to_dict(self) -> Dict[str, object]: return asdict(self)
class PantherAICompilerOptimizer:
    def __init__(self, report_dir: str | Path="build/reports") -> None:
        self.cost_model=AICostModel(); self.pass_manager=PassManager(); self.report_dir=Path(report_dir)
    def parse_source_to_unit(self, source: str, unit_name: str="main") -> OptimizationUnit:
        if not source or not source.strip(): raise ValueError("source cannot be empty")
        nodes=[]
        for idx,line in enumerate(source.splitlines(),1):
            text=line.strip()
            if not text or text.startswith("#"): continue
            if "unreachable" in text or text.startswith("dead "): nodes.append(OptimizationNode("dead", text, {"line":idx,"reachable":False}))
            elif text.startswith("agent ") or "agent.call" in text: nodes.append(OptimizationNode("agent_call", text, {"line":idx}))
            elif text.startswith("workflow "): nodes.append(OptimizationNode("workflow", text, {"line":idx}))
            elif "+" in text and all(part.strip().isdigit() for part in text.split("+") if part.strip()):
                parts=[int(p.strip()) for p in text.split("+")]
                nodes.append(OptimizationNode("expr","+",{"line":idx},[OptimizationNode("literal",parts[0]),OptimizationNode("literal",sum(parts[1:]))]))
            elif text.startswith(("let ","return ","print ")): nodes.append(OptimizationNode("expr", text, {"line":idx}))
            else: nodes.append(OptimizationNode("call", text, {"line":idx}))
        if not nodes: nodes.append(OptimizationNode("constant",0,{"generated":"empty_program_noop"}))
        return OptimizationUnit(unit_name,nodes,{"phase":"6.7","source_lines":len(source.splitlines())})
    def optimize_unit(self, unit: OptimizationUnit) -> OptimizationResult:
        before=self.cost_model.estimate(unit); optimized, diagnostics=self.pass_manager.run(unit); after=self.cost_model.estimate(optimized)
        payload={"unit_name":optimized.name,"before_cost":before.to_dict(),"after_cost":after.to_dict(),"optimized_unit":optimized.to_dict(),"diagnostics":diagnostics,"success":True}
        sha=hashlib.sha256(json.dumps(payload,indent=2,sort_keys=True).encode()).hexdigest(); self.report_dir.mkdir(parents=True,exist_ok=True); rp=self.report_dir/"phase6_7_last_ai_optimization_report.json"
        result=OptimizationResult(optimized.name,before.to_dict(),after.to_dict(),optimized.to_dict(),diagnostics,str(rp),sha,True)
        rp.write_text(json.dumps(result.to_dict(),indent=2,sort_keys=True),encoding="utf-8"); return result
    def optimize_source(self, source: str, unit_name: str="main") -> OptimizationResult:
        return self.optimize_unit(self.parse_source_to_unit(source, unit_name))
