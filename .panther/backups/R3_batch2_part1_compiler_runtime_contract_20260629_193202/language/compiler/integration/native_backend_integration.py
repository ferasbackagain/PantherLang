from __future__ import annotations
from typing import Dict
from language.compiler.native_backend import PantherNativeBackend
def compile_to_native(source: str, target: str="x86_64-unknown-linux-gnu", module_name: str="main") -> Dict[str, object]:
    return PantherNativeBackend().build(source,target,module_name).to_dict()
