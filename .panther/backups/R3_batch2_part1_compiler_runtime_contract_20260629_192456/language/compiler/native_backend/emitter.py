from __future__ import annotations
import hashlib, json
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Dict
from .ir_model import NativeModule
from .target import NativeTarget
@dataclass(slots=True)
class EmissionResult:
    target: str; artifact_path: str; artifact_kind: str; bytes_written: int; sha256: str; diagnostics: list[str]=field(default_factory=list)
    def to_dict(self)->Dict[str,object]: return asdict(self)
class NativeEmitter:
    def emit_object(self,module:NativeModule,target:NativeTarget,output_dir:str|Path)->EmissionResult:
        module.validate(); target.validate(); out=Path(output_dir); out.mkdir(parents=True,exist_ok=True)
        artifact=out/f"{module.name}.{target.object_format}.pobj"
        payload={"format":"panther-native-object-v1","target":target.triple,"module":module.name,"functions":[{"name":f.name,"exports":f.exports,"instructions":[{"opcode":i.opcode,"operands":i.operands} for i in f.instructions]} for f in module.functions],"metadata":module.metadata}
        data=json.dumps(payload,indent=2,sort_keys=True).encode(); artifact.write_bytes(data)
        return EmissionResult(target.triple,str(artifact),"portable-native-object",len(data),hashlib.sha256(data).hexdigest(),["object emission complete"])
