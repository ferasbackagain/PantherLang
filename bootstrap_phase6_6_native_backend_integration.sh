#!/usr/bin/env bash
set -euo pipefail
BACKUP_DIR=".phase_backups/phase6_6_native_backend_$(date +%Y%m%d_%H%M%S)"
banner(){ echo ""; echo "================================================================"; echo "$1"; echo "================================================================"; }
require_project_root(){ if [ ! -d language ] || [ ! -d scripts ] || [ ! -d tests ]; then echo "ERROR: run from PantherLang project root" >&2; exit 1; fi }
write_file(){ mkdir -p "$(dirname "$1")"; cat > "$1"; }
backup_existing(){ mkdir -p "$BACKUP_DIR"; for x in language/compiler/native_backend language/compiler/integration/native_backend_integration.py tests/phase6_6 scripts/verify_phase6_6_native_backend.sh scripts/run_phase6_6_practical_demo.sh docs/phase6/PHASE_6_6_NATIVE_BACKEND_INTEGRATION.md; do if [ -e "$x" ]; then mkdir -p "$BACKUP_DIR/$(dirname "$x")"; cp -a "$x" "$BACKUP_DIR/$x"; fi; done }
write_backend(){
write_file language/compiler/native_backend/__init__.py <<'PYEOF'
"""PantherLang Phase 6.6 native backend integration."""
from .target import NativeTarget, TargetRegistry
from .ir_model import NativeInstruction, NativeFunction, NativeModule
from .emitter import NativeEmitter, EmissionResult
from .linker import NativeLinker, LinkResult
from .backend import PantherNativeBackend, NativeBuildResult
__all__=["NativeTarget","TargetRegistry","NativeInstruction","NativeFunction","NativeModule","NativeEmitter","EmissionResult","NativeLinker","LinkResult","PantherNativeBackend","NativeBuildResult"]
PYEOF
write_file language/compiler/native_backend/target.py <<'PYEOF'
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
PYEOF
write_file language/compiler/native_backend/ir_model.py <<'PYEOF'
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any, Dict, List
@dataclass(slots=True)
class NativeInstruction:
    opcode: str; operands: List[Any]=field(default_factory=list)
    def validate(self)->None:
        if not self.opcode or not isinstance(self.opcode,str): raise ValueError("instruction opcode must be non-empty")
@dataclass(slots=True)
class NativeFunction:
    name: str; instructions: List[NativeInstruction]=field(default_factory=list); exports: bool=False
    def validate(self)->None:
        if not self.name or not self.name.replace("_","").isalnum(): raise ValueError("invalid native function name")
        for i in self.instructions: i.validate()
@dataclass(slots=True)
class NativeModule:
    name: str; functions: List[NativeFunction]=field(default_factory=list); metadata: Dict[str,Any]=field(default_factory=dict)
    def validate(self)->None:
        if not self.name: raise ValueError("module name is required")
        if not self.functions: raise ValueError("native module must contain at least one function")
        for f in self.functions: f.validate()
PYEOF
write_file language/compiler/native_backend/emitter.py <<'PYEOF'
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
PYEOF
write_file language/compiler/native_backend/linker.py <<'PYEOF'
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
PYEOF
write_file language/compiler/native_backend/backend.py <<'PYEOF'
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
PYEOF
write_file language/compiler/integration/native_backend_integration.py <<'PYEOF'
from __future__ import annotations
from typing import Dict
from language.compiler.native_backend import PantherNativeBackend
def compile_to_native(source: str, target: str="x86_64-unknown-linux-gnu", module_name: str="main") -> Dict[str, object]:
    return PantherNativeBackend().build(source,target,module_name).to_dict()
PYEOF
}
write_tests(){
write_file tests/phase6_6/test_native_backend.py <<'PYEOF'
from pathlib import Path
import pytest
from language.compiler.native_backend import PantherNativeBackend, TargetRegistry, NativeTarget
from language.compiler.native_backend.ir_model import NativeModule, NativeFunction, NativeInstruction
from language.compiler.integration.native_backend_integration import compile_to_native
def test_target_registry_lists_core_targets():
    targets=TargetRegistry().list_targets(); assert "x86_64-unknown-linux-gnu" in targets; assert "wasm32-unknown-unknown" in targets
def test_emit_and_link_native_build(tmp_path):
    r=PantherNativeBackend(output_root=tmp_path).build('let x = 1\nprint x', module_name='demo')
    assert r.success is True; assert Path(r.object['artifact_path']).exists(); assert Path(r.executable['executable_path']).exists(); assert r.executable['object_count']==1
def test_integration_adapter_returns_report():
    report=compile_to_native('print "hello"', module_name='adapter_demo'); assert report['success'] is True; assert report['target']=='x86_64-unknown-linux-gnu'
def test_invalid_target_rejected():
    with pytest.raises(KeyError): PantherNativeBackend().build('print 1', 'bad-target')
def test_empty_source_negative():
    with pytest.raises(ValueError): PantherNativeBackend().build('   ')
def test_invalid_module_validation():
    with pytest.raises(ValueError): NativeModule('', [NativeFunction('main',[NativeInstruction('noop')])]).validate()
def test_custom_target_registration():
    reg=TargetRegistry(); reg.register(NativeTarget('x86_64-custom-lab','x86_64','linux')); assert reg.get('x86_64-custom-lab').arch=='x86_64'
PYEOF
}
write_demo(){
write_file scripts/run_phase6_6_practical_demo.sh <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from language.compiler.native_backend import PantherNativeBackend
source = 'let message = "PantherLang native backend"\nprint message\nreturn 0'
r=PantherNativeBackend().build(source, module_name='phase6_6_demo')
print('Phase 6.6 demo ok:', r.success)
print('Target:', r.target)
print('Object:', r.object['artifact_path'])
print('Executable:', r.executable['executable_path'])
PY
SHEOF
chmod +x scripts/run_phase6_6_practical_demo.sh
}
write_verify(){
write_file scripts/verify_phase6_6_native_backend.sh <<'SHEOF'
#!/usr/bin/env bash
set -euo pipefail
echo "Running Phase 6.6 verification"
echo "= PantherLang Phase 6.6 Professional Verification ="
python3 - <<'PY'
from language.compiler.native_backend import TargetRegistry
from language.compiler.integration.native_backend_integration import compile_to_native
assert 'x86_64-unknown-linux-gnu' in TargetRegistry().list_targets()
assert compile_to_native('print 1', module_name='smoke')['success'] is True
print('Imports/positive smoke: PASS')
PY
python3 -m pytest tests/phase6_6 -q && echo "Pytest: PASS"
scripts/run_phase6_6_practical_demo.sh
python3 - <<'PY'
from language.compiler.native_backend import PantherNativeBackend
negative=False
try: PantherNativeBackend().build('', module_name='bad')
except ValueError: negative=True
assert negative
print('Negative tests: PASS')
backend=PantherNativeBackend()
for i in range(80):
    assert backend.build(f'let x = {i}\nprint x', module_name=f'stress_native_{i}').success
print('Stress test: PASS')
PY
mkdir -p build/reports
python3 - <<'PY'
import json, time
from pathlib import Path
summary={"phase":"6.6","name":"Native Backend Integration","status":"PASS","checks":["imports","pytest","demo","negative","stress"],"timestamp":time.time(),"github_push":"postponed until Phase 6.10 full regression"}
Path('build/reports/phase6_6_verification_summary.json').write_text(json.dumps(summary,indent=2,sort_keys=True))
PY
echo "Phase 6.6 verification completed successfully."
SHEOF
chmod +x scripts/verify_phase6_6_native_backend.sh
}
write_docs(){
write_file docs/phase6/PHASE_6_6_NATIVE_BACKEND_INTEGRATION.md <<'EOF'
# Phase 6.6 — Native Backend Integration
Adds a portable native backend foundation for PantherLang: target triples, portable object emission, executable link manifests, and compiler integration through `compile_to_native`.
Reports: `build/reports/phase6_6_verification_summary.json` and `build/reports/phase6_6_last_native_backend_report.json`.
GitHub push remains postponed until Phase 6.10 full regression.
EOF
}
update_changelog(){ local marker="Phase 6.6 - Native Backend Integration"; if [ -f CHANGELOG.md ] && ! grep -q "$marker" CHANGELOG.md; then cat >> CHANGELOG.md <<'EOF'

## Phase 6.6 - Native Backend Integration
Added target triple registry, portable native object emission, executable link manifests, compiler integration adapter, professional verification, practical demo, negative tests, and stress tests.
GitHub push remains postponed until Phase 6.10 full regression.
EOF
fi }
main(){ require_project_root; banner "PantherLang Phase 6.6 - Native Backend Integration"; backup_existing; write_backend; write_tests; write_demo; write_verify; write_docs; update_changelog; echo "Running Phase 6.6 verification"; scripts/verify_phase6_6_native_backend.sh; banner "PantherLang Phase 6.6 bootstrap finished"; echo "Reports: build/reports/phase6_6_verification_summary.json and build/reports/phase6_6_last_native_backend_report.json"; echo "GitHub push remains postponed until Phase 6.10 full regression."; }
main "$@"
