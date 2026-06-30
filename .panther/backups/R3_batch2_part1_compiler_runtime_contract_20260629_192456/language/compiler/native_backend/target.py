from __future__ import annotations
from dataclasses import dataclass
from typing import Dict, List
@dataclass(frozen=True, slots=True)
class NativeTarget:
    triple: str; arch: str; os: str; abi: str="gnu"; object_format: str="elf"; pointer_width: int=64; executable_extension: str=""
    def validate(self)->None:
        if not self.triple or self.triple.count("-")<2: raise ValueError("target triple must contain arch-vendor-os separators")
        if self.arch not in {"x86_64","aarch64","wasm32"}: raise ValueError(f"unsupported target arch: {self.arch}")
        if self.pointer_width not in {32,64}: raise ValueError("pointer_width must be 32 or 64")
class TargetRegistry:
    def __init__(self)->None:
        self._targets: Dict[str,NativeTarget]={}
        for t in [NativeTarget("x86_64-unknown-linux-gnu","x86_64","linux","gnu","elf",64,""),NativeTarget("aarch64-unknown-linux-gnu","aarch64","linux","gnu","elf",64,""),NativeTarget("x86_64-apple-darwin","x86_64","darwin","macho","macho",64,""),NativeTarget("x86_64-pc-windows-msvc","x86_64","windows","msvc","coff",64,".exe"),NativeTarget("wasm32-unknown-unknown","wasm32","unknown","none","wasm",32,".wasm")]: self.register(t)
    def register(self,target:NativeTarget)->None: target.validate(); self._targets[target.triple]=target
    def get(self,triple:str)->NativeTarget:
        if triple not in self._targets: raise KeyError(f"unknown native target: {triple}")
        return self._targets[triple]
    def list_targets(self)->List[str]: return sorted(self._targets)
