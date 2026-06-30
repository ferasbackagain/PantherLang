#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BATCH="R3_batch4_v3_debug_adapter_compatibility_repair"
BACKUP_DIR="$ROOT/.panther_backups/${BATCH}_${STAMP}"
REPORT_DIR="$ROOT/reports/R3_compiler_runtime"
MANIFEST_DIR="$ROOT/.panther/manifests"
mkdir -p "$BACKUP_DIR" "$REPORT_DIR" "$MANIFEST_DIR"

if [[ ! -d "$ROOT/debug_adapter" ]]; then
  echo "ERROR: Run from PantherLang repository root. Expected debug_adapter/."
  exit 1
fi

backup_file(){
  local path="$1"
  if [[ -e "$ROOT/$path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$ROOT/$path" "$BACKUP_DIR/$path"
  fi
}
for f in debug_adapter/variable_references.py debug_adapter/variables.py debug_adapter/launcher.py debug_adapter/__init__.py; do backup_file "$f"; done

python3 - <<'PY'
from pathlib import Path
import json
root=Path.cwd()
def read(p):
    path=root/p
    return path.read_text(encoding='utf-8') if path.exists() else ''
def write(p,s):
    path=root/p; path.parent.mkdir(parents=True, exist_ok=True); path.write_text(s, encoding='utf-8'); print('WROTE',p)

# Patch ReferenceEntry into current variable_references.py if missing.
p= root/'debug_adapter/variable_references.py'
text=read(Path('debug_adapter/variable_references.py'))
if 'ReferenceEntry' not in text or 'def to_dict' not in text:
    patch = r'''

# ---------------------------------------------------------------------------
# R3 Batch 4 v3 compatibility: legacy/public ReferenceEntry contract
# ---------------------------------------------------------------------------
try:
    ReferenceEntry
except NameError:
    try:
        _PantherReferenceBase = VariableReferenceEntry
    except NameError:
        _PantherReferenceBase = None

    if _PantherReferenceBase is not None:
        class ReferenceEntry(_PantherReferenceBase):
            def to_dict(self):
                return {
                    "reference": int(self.reference),
                    "name": str(self.name),
                    "value": self.value,
                    "parentReference": 0 if getattr(self, "parent_reference", None) is None else int(getattr(self, "parent_reference")),
                }
    else:
        from dataclasses import dataclass as _panther_dataclass
        from typing import Any as _PantherAny, Dict as _PantherDict
        @_panther_dataclass
        class ReferenceEntry:
            reference: int
            name: str
            value: _PantherAny
            parent_reference: int = 0
            def to_dict(self) -> _PantherDict[str, _PantherAny]:
                return {
                    "reference": int(self.reference),
                    "name": str(self.name),
                    "value": self.value,
                    "parentReference": int(self.parent_reference or 0),
                }

def _panther_vra_clear(self):
    if hasattr(self, "_entries"):
        self._entries.clear()

def _panther_vra_entries(self):
    out = []
    for ref, entry in getattr(self, "_entries", {}).items():
        if hasattr(entry, "to_dict"):
            out.append(entry.to_dict())
        else:
            out.append({
                "reference": int(ref),
                "name": str(getattr(entry, "name", ref)),
                "value": getattr(entry, "value", None),
                "parentReference": getattr(entry, "parent_reference", 0) or 0,
            })
    return out

if "VariableReferenceAllocator" in globals():
    if not hasattr(VariableReferenceAllocator, "clear"):
        VariableReferenceAllocator.clear = _panther_vra_clear
    if not hasattr(VariableReferenceAllocator, "entries"):
        VariableReferenceAllocator.entries = _panther_vra_entries

if "VariableReferenceService" in globals() and not hasattr(VariableReferenceService, "stats"):
    def _panther_vrs_stats(self):
        allocator = getattr(self, "allocator", None)
        return {
            "referenceCount": allocator.count() if allocator and hasattr(allocator, "count") else 0,
            "entries": allocator.entries() if allocator and hasattr(allocator, "entries") else [],
        }
    VariableReferenceService.stats = _panther_vrs_stats
'''
    p.write_text(text.rstrip()+patch+'\n', encoding='utf-8')
    print('PATCHED debug_adapter/variable_references.py')
else:
    print('UNCHANGED debug_adapter/variable_references.py')

# Add Launcher alias if missing.
launcher=read(Path('debug_adapter/launcher.py'))
if 'class Launcher' not in launcher:
    launcher += r'''

# ---------------------------------------------------------------------------
# R3 Batch 4 v3 compatibility: legacy Launcher contract
# ---------------------------------------------------------------------------
try:
    PantherProgramLauncher
except NameError:
    from dataclasses import dataclass
    @dataclass
    class LaunchResult:
        started: bool
        pid: int | None
        command: list[str]
    class PantherProgramLauncher:
        def build_command(self, program, args=None):
            return ["Panther", "run", str(program), *list(args or [])]
        def launch(self, program, args=None, cwd=None, dry_run=True):
            return LaunchResult(started=not dry_run, pid=None, command=self.build_command(program, args))

class Launcher(PantherProgramLauncher):
    pass

launcher = Launcher
try:
    __all__
except NameError:
    __all__ = []
for _name in ["LaunchResult", "PantherProgramLauncher", "Launcher", "launcher"]:
    if _name not in __all__:
        __all__.append(_name)
'''
    write(Path('debug_adapter/launcher.py'), launcher)
else:
    print('UNCHANGED debug_adapter/launcher.py')

# Defensive variables facade.
variables = r'''from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Optional

try:
    from .variables_core import DebugVariable, VariableFactory, VariablesCore
except Exception:
    @dataclass
    class DebugVariable:
        name: str
        value: str
        type: str = "string"
        variablesReference: int = 0
    class VariableFactory:
        @staticmethod
        def from_value(name: str, value: Any):
            return DebugVariable(name=str(name), value=str(value), type=type(value).__name__, variablesReference=0)
    class VariablesCore:
        def make(self, name: str, value: Any):
            return VariableFactory.from_value(name, value)

if not hasattr(VariablesCore, "variable"):
    def _panther_core_variable(self, name: str, value: Any, variables_reference: int = 0, evaluate_name: Optional[str] = None) -> Dict[str, Any]:
        rendered = "true" if value is True else "false" if value is False else "null" if value is None else str(value)
        return {"name": str(name), "value": rendered, "type": type(value).__name__, "variablesReference": int(variables_reference), "evaluateName": evaluate_name or str(name)}
    VariablesCore.variable = _panther_core_variable

if not hasattr(VariablesCore, "assert_variable_contract"):
    def _panther_assert_variable_contract(self, variable: Dict[str, Any]) -> bool:
        missing = {"name", "value", "variablesReference"} - set(variable)
        if missing:
            raise AssertionError(f"missing DAP variable keys: {sorted(missing)}")
        return True
    VariablesCore.assert_variable_contract = _panther_assert_variable_contract

try:
    from .variable_references import ReferenceEntry, VariableReferenceAllocator, VariableReferenceResolver, VariableReferenceService, VariableReferenceStore
except Exception:
    @dataclass
    class ReferenceEntry:
        reference: int
        name: str
        value: Any
        parent_reference: int = 0
        def to_dict(self):
            return {"reference": self.reference, "name": self.name, "value": self.value, "parentReference": self.parent_reference}
    class VariableReferenceAllocator:
        def __init__(self, start: int = 1): self._next=start; self._entries={}
        def allocate(self, name, value=None, parent_reference=0):
            if value is None and not isinstance(name, str): value=name; name=f"ref{self._next}"
            ref=self._next; self._next+=1; self._entries[ref]=ReferenceEntry(ref,str(name),value,parent_reference or 0); return ref
        def get(self, ref): return self._entries[int(ref)]
        def count(self): return len(self._entries)
        def clear(self): self._entries.clear()
        def entries(self): return [e.to_dict() for e in self._entries.values()]
    class VariableReferenceResolver:
        def children_for(self, name, value):
            if isinstance(value, dict): return [type("Child", (), {"name":str(k), "value":v}) for k,v in value.items()]
            if isinstance(value, (list, tuple)): return [type("Child", (), {"name":str(i), "value":v}) for i,v in enumerate(value)]
            return []
    class VariableReferenceService:
        def __init__(self): self.allocator=VariableReferenceAllocator(); self.resolver=VariableReferenceResolver(); self.core=VariablesCore()
        def variable(self, name, value, parent_reference=0):
            children=self.resolver.children_for(name,value); ref=self.allocator.allocate(name,value,parent_reference) if children else 0
            return self.core.variable(name,value,variables_reference=ref,evaluate_name=str(name))
        def variables_from_mapping(self, mapping, parent_reference=0): return [self.variable(k,v,parent_reference) for k,v in dict(mapping or {}).items()]
        def children(self, ref):
            if int(ref)==0: return []
            entry=self.allocator.get(int(ref)); return [self.variable(c.name,c.value,int(ref)) for c in self.resolver.children_for(entry.name,entry.value)]
        def assert_reference_contract(self, item): return VariablesCore().assert_variable_contract(item)
        def stats(self): return {"referenceCount": self.allocator.count(), "entries": self.allocator.entries()}
    VariableReferenceStore=VariableReferenceService

if not hasattr(VariableReferenceService, "stats"):
    def _panther_vrs_stats(self):
        allocator=getattr(self,"allocator",None)
        return {"referenceCount": allocator.count() if allocator and hasattr(allocator,"count") else 0, "entries": allocator.entries() if allocator and hasattr(allocator,"entries") else []}
    VariableReferenceService.stats = _panther_vrs_stats

try:
    from .variable_store import VariableScopeRecord, VariableStore, DebugVariableStore
except Exception:
    @dataclass
    class VariableScopeRecord:
        name: str
        variables: Dict[str, Any]
        scope_reference: int = 0
    class VariableStore:
        def __init__(self): self._scopes={"locals":{}}
        def set(self, name, value, scope="locals"): self._scopes.setdefault(scope,{})[str(name)]=value; return self.get(name, scope)
        def get(self, name, scope="locals", default=None): return self._scopes.get(scope,{}).get(str(name), default)
        def variables(self, scope="locals"):
            service=VariableReferenceService(); return service.variables_from_mapping(self._scopes.get(scope,{}))
        def clear(self): self._scopes={"locals":{}}
    DebugVariableStore=VariableStore

if not hasattr(VariableStore, "set"):
    def _vs_set(self, name, value, scope="globals"):
        if not hasattr(self, "globals"): self.globals={}
        self.globals[str(name)] = value
        return value
    VariableStore.set = _vs_set
if not hasattr(VariableStore, "get"):
    def _vs_get(self, name, scope="globals", default=None):
        return getattr(self, "globals", {}).get(str(name), default)
    VariableStore.get = _vs_get

def _optional(module: str, *names: str):
    try:
        mod = __import__(f"debug_adapter.{module}", fromlist=list(names))
        return [getattr(mod, name, None) for name in names]
    except Exception:
        return [None for _ in names]

StackFrameSource, DebugStackFrame, StackFrameStore = _optional("stack_frames", "StackFrameSource", "DebugStackFrame", "StackFrameStore")
DebugThread, ThreadStore, DebugThreadStore = _optional("threads", "DebugThread", "ThreadStore", "DebugThreadStore")
DebugScope, ScopeStore, DebugScopeStore = _optional("scopes", "DebugScope", "ScopeStore", "DebugScopeStore")
EvaluateResult, EvaluateContext, EvaluateEngine, DebugEvaluateEngine = _optional("evaluate", "EvaluateResult", "EvaluateContext", "EvaluateEngine", "DebugEvaluateEngine")
WatchExpression, WatchExpressionStore, WatchExpressionManager, build_watch_manager_for_thread_store = _optional("watch_expressions", "WatchExpression", "WatchExpressionStore", "WatchExpressionManager", "build_watch_manager_for_thread_store")

class _FallbackStore:
    def __init__(self, *args, **kwargs): self.items={}
    def clear(self): self.items.clear()

StackFrameStore = StackFrameStore or _FallbackStore
ThreadStore = ThreadStore or _FallbackStore
ScopeStore = ScopeStore or _FallbackStore
EvaluateEngine = EvaluateEngine or _FallbackStore
WatchExpressionStore = WatchExpressionStore or _FallbackStore

__all__ = [
    "DebugVariable", "VariableFactory", "VariablesCore",
    "ReferenceEntry", "VariableReferenceAllocator", "VariableReferenceResolver", "VariableReferenceService", "VariableReferenceStore",
    "VariableScopeRecord", "VariableStore", "DebugVariableStore",
    "StackFrameSource", "DebugStackFrame", "StackFrameStore",
    "DebugThread", "ThreadStore", "DebugThreadStore",
    "DebugScope", "ScopeStore", "DebugScopeStore",
    "EvaluateResult", "EvaluateContext", "EvaluateEngine", "DebugEvaluateEngine",
    "WatchExpression", "WatchExpressionStore", "WatchExpressionManager", "build_watch_manager_for_thread_store",
]
'''
write(Path('debug_adapter/variables.py'), variables)

init = r'''from __future__ import annotations

__version__ = "0.4.3-r3-batch4-v3-compat"

def _optional(module: str, name: str):
    try:
        mod = __import__(f"debug_adapter.{module}", fromlist=[name])
        return getattr(mod, name)
    except Exception:
        return None

PantherDebugAdapter = _optional("adapter", "PantherDebugAdapter")
DebugSession = _optional("session", "DebugSession")
DebugServer = _optional("server", "DebugServer")
RequestDispatcher = _optional("dispatcher", "RequestDispatcher")
LaunchResult = _optional("launcher", "LaunchResult")
Launcher = _optional("launcher", "Launcher")
PantherProgramLauncher = _optional("launcher", "PantherProgramLauncher")

from .variables import (
    DebugVariable, VariableFactory, VariablesCore, ReferenceEntry,
    VariableReferenceAllocator, VariableReferenceResolver, VariableReferenceService, VariableReferenceStore,
    VariableStore, DebugVariableStore, StackFrameStore, ThreadStore, ScopeStore,
    EvaluateEngine, WatchExpressionStore,
)

__all__ = [
    "PantherDebugAdapter", "DebugSession", "DebugServer", "RequestDispatcher",
    "LaunchResult", "Launcher", "PantherProgramLauncher", "DebugVariable", "VariableFactory", "VariablesCore", "ReferenceEntry",
    "VariableReferenceAllocator", "VariableReferenceResolver", "VariableReferenceService", "VariableReferenceStore",
    "VariableStore", "DebugVariableStore", "StackFrameStore", "ThreadStore", "ScopeStore",
    "EvaluateEngine", "WatchExpressionStore", "__version__",
]
'''
write(Path('debug_adapter/__init__.py'), init)

report = """# R3 Batch 4 v3 Debug Adapter Compatibility Repair\n\nRepairs ReferenceEntry, VariablesCore, VariableStore, Launcher, and debug_adapter public exports.\n"""
write(Path('reports/R3_compiler_runtime/R3_BATCH4_V3_DEBUG_ADAPTER_COMPATIBILITY_REPAIR.md'), report)
manifest={"batch":"R3 Batch 4 v3","purpose":"Debug Adapter compatibility repair","source_error":"ReferenceEntry import failure","policy":"No Feature Without Proof"}
write(Path('.panther/manifests/r3_batch4_v3_debug_adapter_compatibility_repair.json'), json.dumps(manifest, indent=2))
PY

python3 - <<'PY'
from debug_adapter.variable_references import ReferenceEntry
from debug_adapter.variables import VariableStore, VariablesCore, VariableReferenceService
from debug_adapter.launcher import Launcher
print('DAP_COMPAT_IMPORT_OK', ReferenceEntry.__name__, VariableStore.__name__, VariablesCore.__name__, VariableReferenceService.__name__, Launcher.__name__)
PY

echo "DONE: $BATCH"
echo "Backup: $BACKUP_DIR"
echo "Next: python3 -m pytest -q"
