#!/usr/bin/env bash
set -euo pipefail
BACKUP_DIR=".phase_backups/phase6_7_ai_compiler_optimization_$(date +%Y%m%d_%H%M%S)"
banner(){ echo ""; echo "================================================================"; echo "$1"; echo "================================================================"; }
require_project_root(){ if [ ! -d language ] || [ ! -d scripts ] || [ ! -d tests ]; then echo "ERROR: run from PantherLang project root" >&2; exit 1; fi }
write_file(){ mkdir -p "$(dirname "$1")"; cat > "$1"; }
backup_existing(){ mkdir -p "$BACKUP_DIR"; for x in language/compiler/ai_optimization language/compiler/integration/ai_optimizer_integration.py tests/phase6_7 scripts/verify_phase6_7_ai_compiler_optimization.sh scripts/run_phase6_7_practical_demo.sh docs/phase6/PHASE_6_7_AI_COMPILER_OPTIMIZATION.md; do if [ -e "$x" ]; then mkdir -p "$BACKUP_DIR/$(dirname "$x")"; cp -a "$x" "$BACKUP_DIR/$x"; fi; done }
write_optimizer(){
write_file language/compiler/ai_optimization/__init__.py <<'PYEOF'
"""PantherLang Phase 6.7 AI compiler optimization."""
from .ir import OptimizationNode, OptimizationUnit
from .passes import OptimizationPass, ConstantFoldingPass, DeadCodeEliminationPass, AgentHintPass, PassManager
from .cost_model import AICostModel, CostEstimate
from .optimizer import PantherAICompilerOptimizer, OptimizationResult
__all__=["OptimizationNode","OptimizationUnit","OptimizationPass","ConstantFoldingPass","DeadCodeEliminationPass","AgentHintPass","PassManager","AICostModel","CostEstimate","PantherAICompilerOptimizer","OptimizationResult"]
PYEOF
write_file language/compiler/ai_optimization/ir.py <<'PYEOF'
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any, Dict, List
@dataclass(slots=True)
class OptimizationNode:
    kind: str
    value: Any = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    children: List["OptimizationNode"] = field(default_factory=list)
    def validate(self) -> None:
        if not self.kind or not isinstance(self.kind, str): raise ValueError("optimization node kind must be a non-empty string")
        for child in self.children: child.validate()
    def to_dict(self) -> Dict[str, Any]:
        return {"kind": self.kind, "value": self.value, "metadata": self.metadata, "children": [c.to_dict() for c in self.children]}
@dataclass(slots=True)
class OptimizationUnit:
    name: str
    nodes: List[OptimizationNode] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    def validate(self) -> None:
        if not self.name: raise ValueError("optimization unit name is required")
        if not self.nodes: raise ValueError("optimization unit must contain at least one node")
        for node in self.nodes: node.validate()
    def to_dict(self) -> Dict[str, Any]:
        return {"name": self.name, "nodes": [n.to_dict() for n in self.nodes], "metadata": self.metadata}
PYEOF
write_file language/compiler/ai_optimization/cost_model.py <<'PYEOF'
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
PYEOF
write_file language/compiler/ai_optimization/passes.py <<'PYEOF'
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
PYEOF
write_file language/compiler/ai_optimization/optimizer.py <<'PYEOF'
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
PYEOF
write_file language/compiler/integration/ai_optimizer_integration.py <<'PYEOF'
from __future__ import annotations
from typing import Dict
from language.compiler.ai_optimization import PantherAICompilerOptimizer
def optimize_with_ai_compiler(source: str, unit_name: str="main") -> Dict[str, object]:
    return PantherAICompilerOptimizer().optimize_source(source, unit_name).to_dict()
PYEOF
}
write_tests(){
write_file tests/phase6_7/test_ai_compiler_optimization.py <<'PYEOF'
from pathlib import Path
import pytest
from language.compiler.ai_optimization import PantherAICompilerOptimizer, OptimizationNode, OptimizationUnit, AICostModel
from language.compiler.ai_optimization.passes import ConstantFoldingPass, DeadCodeEliminationPass, AgentHintPass
from language.compiler.integration.ai_optimizer_integration import optimize_with_ai_compiler

def test_constant_folding_pass():
    unit=OptimizationUnit('fold',[OptimizationNode('expr','+',{},[OptimizationNode('literal',2),OptimizationNode('literal',3)])])
    optimized, diagnostics=ConstantFoldingPass().run(unit)
    assert optimized.nodes[0].kind=='constant' and optimized.nodes[0].value==5
    assert diagnostics

def test_dead_code_elimination():
    unit=OptimizationUnit('dce',[OptimizationNode('expr','live'),OptimizationNode('dead','unreachable')])
    optimized, diagnostics=DeadCodeEliminationPass().run(unit)
    assert len(optimized.nodes)==1 and optimized.nodes[0].value=='live'
    assert diagnostics

def test_agent_hint_enrichment():
    unit=OptimizationUnit('agent',[OptimizationNode('agent_call','agent scout')])
    optimized, diagnostics=AgentHintPass().run(unit)
    assert optimized.nodes[0].metadata['ai_optimization_hint']
    assert optimized.nodes[0].metadata['safety']

def test_optimizer_source_report(tmp_path):
    result=PantherAICompilerOptimizer(report_dir=tmp_path).optimize_source('2 + 3\nagent scout\ndead unreachable', 'demo')
    assert result.success is True
    assert Path(result.report_path).exists()
    assert result.after_cost['node_count'] <= result.before_cost['node_count']

def test_integration_adapter():
    report=optimize_with_ai_compiler('workflow incident_response\nagent analyst', 'adapter_demo')
    assert report['success'] is True
    assert report['optimized_unit']['name']=='adapter_demo'

def test_negative_empty_source():
    with pytest.raises(ValueError): PantherAICompilerOptimizer().optimize_source('   ')

def test_cost_model_rejects_invalid_unit():
    with pytest.raises(ValueError): AICostModel().estimate(OptimizationUnit('', []))
PYEOF
}
write_demo(){
write_file scripts/run_phase6_7_practical_demo.sh <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from language.compiler.ai_optimization import PantherAICompilerOptimizer
source = "\n2 + 3\nagent threat_hunter\nworkflow incident_response\ndead unreachable_branch\nprint result\n"
r=PantherAICompilerOptimizer().optimize_source(source, unit_name='phase6_7_demo')
print('Phase 6.7 demo ok:', r.success)
print('Before cost:', r.before_cost['estimated_runtime_cost'])
print('After cost:', r.after_cost['estimated_runtime_cost'])
print('Nodes after:', r.after_cost['node_count'])
print('Report:', r.report_path)
PY
SHEOF
chmod +x scripts/run_phase6_7_practical_demo.sh
}
write_verify(){
write_file scripts/verify_phase6_7_ai_compiler_optimization.sh <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Running Phase 6.7 verification"
echo "= PantherLang Phase 6.7 Professional Verification ="
python3 - <<'PY'
from language.compiler.ai_optimization import PantherAICompilerOptimizer
from language.compiler.integration.ai_optimizer_integration import optimize_with_ai_compiler
assert PantherAICompilerOptimizer().optimize_source('1 + 2', 'smoke').success is True
assert optimize_with_ai_compiler('agent smoke', 'smoke_adapter')['success'] is True
print('Imports/positive smoke: PASS')
PY
python3 -m pytest tests/phase6_7 -q && echo "Pytest: PASS"
scripts/run_phase6_7_practical_demo.sh
python3 - <<'PY'
from language.compiler.ai_optimization import PantherAICompilerOptimizer
negative=False
try: PantherAICompilerOptimizer().optimize_source('   ')
except ValueError: negative=True
assert negative
print('Negative tests: PASS')
opt=PantherAICompilerOptimizer()
for i in range(120):
    src=f'{i} + {i+1}\nagent stress_{i}\ndead unreachable_{i}'
    r=opt.optimize_source(src, unit_name=f'stress_ai_opt_{i}')
    assert r.success and r.after_cost['node_count'] <= r.before_cost['node_count']
print('Stress test: PASS')
PY
mkdir -p build/reports
python3 - <<'PY'
import json, time
from pathlib import Path
summary={"phase":"6.7","name":"AI Compiler Optimization","status":"PASS","checks":["imports","pytest","demo","negative","stress"],"timestamp":time.time(),"github_push":"postponed until Phase 6.10 full regression"}
Path('build/reports/phase6_7_verification_summary.json').write_text(json.dumps(summary,indent=2,sort_keys=True))
PY
echo "Phase 6.7 verification completed successfully."
SHEOF
chmod +x scripts/verify_phase6_7_ai_compiler_optimization.sh
}
write_docs(){
write_file docs/phase6/PHASE_6_7_AI_COMPILER_OPTIMIZATION.md <<'EOF'
# Phase 6.7 — AI Compiler Optimization
Adds a compiler optimization layer designed for AI-native PantherLang workloads: optimization IR, AI-aware cost model, constant folding, dead-code elimination, agent/workflow hints, pass manager, integration adapter, verification, demo, negative tests, and stress tests.
Reports: `build/reports/phase6_7_verification_summary.json` and `build/reports/phase6_7_last_ai_optimization_report.json`.
GitHub push remains postponed until Phase 6.10 full regression.
EOF
}
update_changelog(){ local marker="Phase 6.7 - AI Compiler Optimization"; if [ -f CHANGELOG.md ] && ! grep -q "$marker" CHANGELOG.md; then cat >> CHANGELOG.md <<'EOF'

## Phase 6.7 - AI Compiler Optimization
Added AI-aware compiler optimization IR, cost model, pass manager, constant folding, dead-code elimination, agent/workflow optimization hints, integration adapter, professional verification, practical demo, negative tests, and stress tests.
GitHub push remains postponed until Phase 6.10 full regression.
EOF
fi }
main(){ banner "PantherLang Phase 6.7 - AI Compiler Optimization"; require_project_root; backup_existing; write_optimizer; write_tests; write_demo; write_verify; write_docs; update_changelog; echo "Running Phase 6.7 verification"; scripts/verify_phase6_7_ai_compiler_optimization.sh; banner "PantherLang Phase 6.7 bootstrap finished"; echo "Reports: build/reports/phase6_7_verification_summary.json and build/reports/phase6_7_last_ai_optimization_report.json"; echo "GitHub push remains postponed until Phase 6.10 full regression."; }
main "$@"
