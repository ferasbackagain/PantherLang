from __future__ import annotations
import hashlib, json
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Dict, Iterable
from .emitter import EmissionResult
from .target import NativeTarget
@dataclass(slots=True)
class LinkResult:
    target: str; executable_path: str; bytes_written: int; sha256: str; object_count: int; diagnostics: list[str]=field(default_factory=list)
    def to_dict(self)->Dict[str,object]: return asdict(self)
class NativeLinker:
    def link(self,objects:Iterable[EmissionResult],target:NativeTarget,output_dir:str|Path,name:str="panther_app")->LinkResult:
        target.validate(); objs=list(objects)
        if not objs: raise ValueError("at least one emitted object is required for native linking")
        for o in objs:
            if o.target!=target.triple: raise ValueError("cannot link objects emitted for a different target")
        out=Path(output_dir); out.mkdir(parents=True,exist_ok=True); exe=out/f"{name}{target.executable_extension}.panther-native"
        payload={"format":"panther-native-executable-v1","target":target.triple,"objects":[o.to_dict() for o in objs],"entry":"main"}
        data=json.dumps(payload,indent=2,sort_keys=True).encode(); exe.write_bytes(data)
        return LinkResult(target.triple,str(exe),len(data),hashlib.sha256(data).hexdigest(),len(objs),["native link complete"])
