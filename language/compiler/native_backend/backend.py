from __future__ import annotations
import json
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Dict
from .emitter import NativeEmitter
from .ir_model import NativeFunction, NativeInstruction, NativeModule
from .linker import NativeLinker
from .target import TargetRegistry
@dataclass(slots=True)
class NativeBuildResult:
    module: str; target: str; object: Dict[str,object]; executable: Dict[str,object]; report_path: str; success: bool=True; diagnostics: list[str]=field(default_factory=list)
    def to_dict(self)->Dict[str,object]: return asdict(self)
class PantherNativeBackend:
    def __init__(self,output_root:str|Path="build/native")->None:
        self.targets=TargetRegistry(); self.emitter=NativeEmitter(); self.linker=NativeLinker(); self.output_root=Path(output_root)
    def lower_source_to_module(self,source:str,module_name:str="main")->NativeModule:
        if not source or not source.strip(): raise ValueError("source cannot be empty")
        instructions=[]
        for idx,line in enumerate(source.splitlines(),1):
            text=line.strip()
            if not text or text.startswith("#"): continue
            opcode="lowered_statement" if text.startswith(("print","let","return","async")) else "lowered_expression"
            instructions.append(NativeInstruction(opcode,[idx,text]))
        if not instructions: instructions.append(NativeInstruction("noop",[]))
        return NativeModule(module_name,[NativeFunction("main",instructions,True)],{"lowering":"phase6.6"})
    def build(self,source:str,target_triple:str="x86_64-unknown-linux-gnu",module_name:str="main")->NativeBuildResult:
        target=self.targets.get(target_triple); module=self.lower_source_to_module(source,module_name)
        obj=self.emitter.emit_object(module,target,self.output_root/target.triple/"obj")
        exe=self.linker.link([obj],target,self.output_root/target.triple/"bin",module.name)
        report=NativeBuildResult(module.name,target.triple,obj.to_dict(),exe.to_dict(),"",True,["native backend build complete"])
        reports=Path("build/reports"); reports.mkdir(parents=True,exist_ok=True); rp=reports/"phase6_6_last_native_backend_report.json"; report.report_path=str(rp)
        rp.write_text(json.dumps(report.to_dict(),indent=2,sort_keys=True),encoding="utf-8"); return report
