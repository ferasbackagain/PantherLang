#!/usr/bin/env bash
set -euo pipefail
PHASE="6.4"
PHASE_NAME="Advanced Type Inference"
VERSION="0.6.4-advanced-type-inference"
ROOT="$(pwd)"
PYTHON_BIN="${PYTHON:-python3}"
printf '\n============================================================\n'
printf ' PantherLang Phase %s — %s\n' "$PHASE" "$PHASE_NAME"
printf '============================================================\n'
if [ ! -d "language" ] || [ ! -d "tests" ]; then echo "❌ Run this script from the PantherLang project root."; exit 1; fi
mkdir -p language/compiler/type_inference tests/phase6_4 scripts docs/phase6 examples/types build/reports build/phase6_4_demo_workspace .phase_backups
BACKUP_DIR=".phase_backups/phase6_4_advanced_type_inference_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
for f in CHANGELOG.md VERSION_PLAN.md README.md HOW_TO_USE_THIS_RELEASE.md; do [ -f "$f" ] && cp "$f" "$BACKUP_DIR/$f"; done
[ -d "language/compiler/type_inference" ] && cp -R language/compiler/type_inference "$BACKUP_DIR/type_inference.previous" 2>/dev/null || true
cat > language/compiler/type_inference/__init__.py <<'PY64INIT'
from .advanced_type_inference import AdvancedTypeInferenceEngine, InferenceDiagnostic, InferenceResult, PantherType, TypeInferenceError
__all__ = ["AdvancedTypeInferenceEngine", "InferenceDiagnostic", "InferenceResult", "PantherType", "TypeInferenceError"]
PY64INIT
cat > language/compiler/type_inference/advanced_type_inference.py <<'PY64ENGINE'
from __future__ import annotations
import json, re, time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple
try:
    from language.compiler.workspace import WorkspaceManager
except Exception:
    WorkspaceManager = None  # type: ignore
class TypeInferenceError(RuntimeError): pass
@dataclass(frozen=True)
class PantherType:
    name: str
    params: Tuple["PantherType", ...] = ()
    def __str__(self) -> str:
        return self.name if not self.params else f"{self.name}<" + ", ".join(str(p) for p in self.params) + ">"
    @staticmethod
    def parse(text: str) -> "PantherType":
        text = (text or "").strip()
        aliases = {"int":"Int","float":"Float","bool":"Bool","boolean":"Bool","string":"String","str":"String","null":"Null","any":"Any","unknown":"Unknown","never":"Never"}
        if not text: return PantherType("Unknown")
        if "|" in text: return PantherType("Union", tuple(PantherType.parse(p.strip()) for p in text.split("|") if p.strip()))
        m = re.fullmatch(r"([A-Za-z_][A-Za-z0-9_]*)\s*<\s*(.+)\s*>", text)
        if m:
            name, inner = m.groups(); return PantherType(aliases.get(name.lower(), name), tuple(PantherType.parse(p.strip()) for p in split_top_level(inner, ",")))
        return PantherType(aliases.get(text.lower(), text))
INT=PantherType("Int"); FLOAT=PantherType("Float"); BOOL=PantherType("Bool"); STRING=PantherType("String"); NULL=PantherType("Null"); ANY=PantherType("Any"); UNKNOWN=PantherType("Unknown"); NEVER=PantherType("Never")
def split_top_level(text: str, sep: str) -> List[str]:
    out=[]; depth=0; quote=None; start=0
    for i,ch in enumerate(text):
        if quote:
            if ch == quote and (i == 0 or text[i-1] != "\\"): quote=None
            continue
        if ch in {'"', "'"}: quote=ch
        elif ch in "(<[{": depth += 1
        elif ch in ")>]}": depth=max(0, depth-1)
        elif ch == sep and depth == 0:
            out.append(text[start:i].strip()); start=i+1
    tail=text[start:].strip()
    if tail: out.append(tail)
    return out
@dataclass
class InferenceDiagnostic:
    level: str; code: str; message: str; line: int = 0; symbol: Optional[str] = None
    def to_dict(self) -> Dict[str, Any]: return asdict(self)
@dataclass
class InferenceResult:
    ok: bool; phase: str; version: str; source: str; symbols: Dict[str,str]; functions: Dict[str,Dict[str,Any]]; diagnostics: List[InferenceDiagnostic]
    expression_types: Dict[str,str] = field(default_factory=dict); duration_ms: float = 0.0; external_api_used: bool = False; network_required: bool = False
    def to_dict(self) -> Dict[str, Any]:
        data=asdict(self); data["diagnostics"]=[d.to_dict() for d in self.diagnostics]; return data
    def to_json(self) -> str: return json.dumps(self.to_dict(), indent=2, sort_keys=True, ensure_ascii=False)
class AdvancedTypeInferenceEngine:
    phase="6.4"; version="0.6.4-advanced-type-inference"
    typed_let_re=re.compile(r"^\s*let\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*([^=]+?)\s*=\s*(.+?)\s*;?\s*$")
    let_re=re.compile(r"^\s*let\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?)\s*;?\s*$")
    fn_re=re.compile(r"fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\((.*?)\)\s*(?:->\s*([A-Za-z_][A-Za-z0-9_<>, |]*))?\s*\{(.*?)\}", re.DOTALL)
    return_re=re.compile(r"return\s+(.+?)\s*;?(?:\n|$)", re.DOTALL)
    call_re=re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\((.*)\)$")
    def __init__(self) -> None: self.symbols={}; self.functions={}; self.diagnostics=[]; self.expression_types={}
    def reset(self) -> None: self.symbols.clear(); self.functions.clear(); self.diagnostics.clear(); self.expression_types.clear()
    def add_diag(self, level, code, message, line=0, symbol=None): self.diagnostics.append(InferenceDiagnostic(level, code, message, line, symbol))
    def compatible(self, declared: PantherType, inferred: PantherType) -> bool:
        if declared.name == "Any" or inferred.name == "Any": return True
        if declared == inferred: return True
        if declared.name == "Float" and inferred.name == "Int": return True
        if declared.name == "Union": return any(self.compatible(p, inferred) for p in declared.params)
        if declared.name == inferred.name and len(declared.params) == len(inferred.params): return all(self.compatible(a,b) for a,b in zip(declared.params, inferred.params))
        return False
    def unify(self, types: Iterable[PantherType]) -> PantherType:
        clean=[t for t in types if t.name != "Never"]
        if not clean: return NEVER
        if all(t == clean[0] for t in clean): return clean[0]
        if all(t.name in {"Int","Float"} for t in clean): return FLOAT if any(t.name == "Float" for t in clean) else INT
        unique=[]
        for t in clean:
            if t not in unique: unique.append(t)
        return PantherType("Union", tuple(unique))
    def find_top_level_operator(self, expr: str, op: str) -> int:
        depth=0; quote=None; i=len(expr)-len(op)
        while i >= 0:
            ch=expr[i]
            if quote:
                if ch == quote and (i == 0 or expr[i-1] != "\\"): quote=None
                i-=1; continue
            if ch in {'"', "'"}: quote=ch
            elif ch in ")>]}": depth+=1
            elif ch in "(<[{": depth=max(0, depth-1)
            elif depth == 0 and expr[i:i+len(op)] == op:
                if op in {"+","-"} and i == 0: i-=1; continue
                return i
            i-=1
        return -1
    def infer_literal_or_atom(self, expr: str, line: int = 0) -> PantherType:
        expr=expr.strip().rstrip(";")
        if re.fullmatch(r"-?\d+", expr): return INT
        if re.fullmatch(r"-?\d+\.\d+", expr): return FLOAT
        if re.fullmatch(r'"(?:\\.|[^"\\])*"', expr) or re.fullmatch(r"'(?:\\.|[^'\\])*'", expr): return STRING
        if expr in {"true","false"}: return BOOL
        if expr == "null": return NULL
        if expr.startswith("[") and expr.endswith("]"):
            inner=expr[1:-1].strip(); return PantherType("List", (NEVER if not inner else self.unify([self.infer_expression(p,line) for p in split_top_level(inner, ",")]),))
        if expr.startswith("{") and expr.endswith("}"):
            inner=expr[1:-1].strip()
            if not inner: return PantherType("Map", (STRING, NEVER))
            keys=[]; vals=[]
            for pair in split_top_level(inner, ","):
                if ":" not in pair: self.add_diag("error", "PANTHER-TYPE-064-MAP", f"Invalid map literal entry: {pair}", line); return UNKNOWN
                k,v=pair.split(":",1); keys.append(self.infer_expression(k.strip(),line)); vals.append(self.infer_expression(v.strip(),line))
            return PantherType("Map", (self.unify(keys), self.unify(vals)))
        if expr in self.symbols: return self.symbols[expr]
        call=self.call_re.fullmatch(expr)
        if call: return self.infer_call(call.group(1), call.group(2), line)
        self.add_diag("warning", "PANTHER-TYPE-064-UNKNOWN", f"Could not infer expression type: {expr}", line); return UNKNOWN
    def infer_binary(self, expr: str, line: int = 0) -> PantherType:
        for op in ["&&","||","==","!=",">=","<=",">","<"]:
            idx=self.find_top_level_operator(expr, op)
            if idx >= 0:
                left=self.infer_expression(expr[:idx], line); right=self.infer_expression(expr[idx+len(op):], line)
                if op in {"&&","||"} and (left.name != "Bool" or right.name != "Bool"): self.add_diag("error", "PANTHER-TYPE-064-BOOL", f"Boolean operator {op} requires Bool operands", line)
                return BOOL
        for op in ["+","-","*","/"]:
            idx=self.find_top_level_operator(expr, op)
            if idx >= 0:
                left=self.infer_expression(expr[:idx], line); right=self.infer_expression(expr[idx+1:], line)
                if op == "+" and left.name == right.name == "String": return STRING
                if left.name in {"Int","Float"} and right.name in {"Int","Float"}: return FLOAT if op == "/" or "Float" in {left.name,right.name} else INT
                self.add_diag("error", "PANTHER-TYPE-064-BINARY", f"Operator {op} cannot combine {left} and {right}", line); return UNKNOWN
        return self.infer_literal_or_atom(expr, line)
    def infer_expression(self, expr: str, line: int = 0) -> PantherType:
        expr=expr.strip().rstrip(";")
        if expr.startswith("(") and expr.endswith(")"): return self.infer_expression(expr[1:-1], line)
        inferred=self.infer_binary(expr, line); self.expression_types[expr]=str(inferred); return inferred
    def parse_functions(self, source: str) -> None:
        for match in self.fn_re.finditer(source):
            name, params_src, annotated_return, body = match.groups(); params=[]
            if params_src.strip():
                for part in split_top_level(params_src, ","):
                    if ":" not in part: self.add_diag("error", "PANTHER-TYPE-064-PARAM", f"Function parameter requires type annotation: {part.strip()}", 0, name); continue
                    pname, ptype = part.split(":",1); params.append((pname.strip(), PantherType.parse(ptype.strip())))
            previous=dict(self.symbols)
            for pname,ptype in params: self.symbols[pname]=ptype
            ret_match=self.return_re.search(body + "\n"); inferred_return=self.infer_expression(ret_match.group(1), 0) if ret_match else PantherType("Void")
            declared_return=PantherType.parse(annotated_return) if annotated_return else inferred_return
            if annotated_return and not self.compatible(declared_return, inferred_return): self.add_diag("error", "PANTHER-TYPE-064-RETURN", f"Function {name} declares {declared_return} but returns {inferred_return}", 0, name)
            self.functions[name]={"params":[{"name":p,"type":str(t)} for p,t in params], "return_type":str(declared_return), "inferred_return_type":str(inferred_return)}
            self.symbols=previous
    def infer_call(self, name: str, args_src: str, line: int = 0) -> PantherType:
        if name not in self.functions: self.add_diag("warning", "PANTHER-TYPE-064-CALL", f"Unknown function call: {name}", line, name); return UNKNOWN
        fn=self.functions[name]; args=[] if not args_src.strip() else split_top_level(args_src, ","); params=fn["params"]
        if len(args) != len(params): self.add_diag("error", "PANTHER-TYPE-064-ARITY", f"Function {name} expects {len(params)} args but got {len(args)}", line, name)
        for raw_arg,param in zip(args, params):
            inferred=self.infer_expression(raw_arg, line); declared=PantherType.parse(param["type"])
            if not self.compatible(declared, inferred): self.add_diag("error", "PANTHER-TYPE-064-ARG", f"Argument for {name}.{param['name']} expects {declared} but got {inferred}", line, name)
        return PantherType.parse(str(fn["return_type"]))
    def analyze_line(self, line_text: str, line_no: int) -> None:
        stripped=line_text.strip()
        if not stripped or stripped.startswith("#") or stripped.startswith("//") or stripped.startswith("import "): return
        typed=self.typed_let_re.match(stripped)
        if typed:
            name, declared_src, expr=typed.groups(); declared=PantherType.parse(declared_src); inferred=self.infer_expression(expr, line_no); self.symbols[name]=declared
            if not self.compatible(declared, inferred): self.add_diag("error", "PANTHER-TYPE-064-ASSIGN", f"{name} declared as {declared} but expression inferred as {inferred}", line_no, name)
            return
        untyped=self.let_re.match(stripped)
        if untyped:
            name, expr=untyped.groups(); self.symbols[name]=self.infer_expression(expr, line_no)
    def analyze_source(self, source: str, source_name: str = "<memory>") -> InferenceResult:
        started=time.perf_counter(); self.reset()
        if not source.strip(): raise TypeInferenceError("Cannot infer types from empty source")
        self.parse_functions(source); rest=self.fn_re.sub("", source)
        for line_no,line in enumerate(rest.splitlines(), start=1): self.analyze_line(line, line_no)
        ok=not any(d.level == "error" for d in self.diagnostics)
        return InferenceResult(ok, self.phase, self.version, source_name, {k:str(v) for k,v in sorted(self.symbols.items())}, self.functions, list(self.diagnostics), dict(sorted(self.expression_types.items())), round((time.perf_counter()-started)*1000,3), False, False)
    def analyze_file(self, path: str | Path) -> InferenceResult:
        p=Path(path)
        if not p.exists(): raise TypeInferenceError(f"Source file not found: {p}")
        return self.analyze_source(p.read_text(encoding="utf-8"), str(p))
    def analyze_workspace(self, workspace: str | Path) -> Dict[str, Any]:
        if WorkspaceManager is None: raise TypeInferenceError("WorkspaceManager is unavailable; Phase 6.3 is required before Phase 6.4")
        started=time.perf_counter(); manager=WorkspaceManager(cache_dir="build/workspace_cache"); manifest=manager.load_manifest(workspace); root=Path(workspace); root=root.parent if root.is_file() else root
        module_results={}; ok=True
        for module in manager.resolve_modules(workspace):
            module_root=root / module.root; files=[]
            for pattern in module.sources:
                direct = root / pattern
                if direct.is_file(): files.append(direct)
                else: files.extend(sorted(module_root.glob(pattern)))
            for file_path in sorted(set(files)):
                result=AdvancedTypeInferenceEngine().analyze_file(file_path); module_results[str(file_path)]=result.to_dict(); ok = ok and result.ok
        report={"ok":ok,"phase":self.phase,"version":self.version,"workspace":str(workspace),"manifest":manifest.to_dict(),"files_analyzed":len(module_results),"results":module_results,"duration_ms":round((time.perf_counter()-started)*1000,3),"external_api_used":False,"network_required":False}
        Path("build/reports").mkdir(parents=True, exist_ok=True); Path("build/reports/phase6_4_last_inference_report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
        return report
PY64ENGINE
cat > tests/phase6_4/test_advanced_type_inference.py <<'PY64TEST'
from __future__ import annotations
import json
from pathlib import Path
import pytest
from language.compiler.type_inference import AdvancedTypeInferenceEngine, TypeInferenceError

def test_positive_infers_literals_collections_and_functions() -> None:
    src = '''
fn add(a: Int, b: Int) -> Int { return a + b }
let x = 41
let y = 1
let z = add(x, y)
let title = "Panther" + "Lang"
let scores = [1, 2, 3]
let profile = {"name": "Feras", "project": "PantherLang"}
let ready: Bool = true
'''
    result = AdvancedTypeInferenceEngine().analyze_source(src)
    assert result.ok is True
    assert result.phase == "6.4"
    assert result.version == "0.6.4-advanced-type-inference"
    assert result.symbols["x"] == "Int"
    assert result.symbols["z"] == "Int"
    assert result.symbols["title"] == "String"
    assert result.symbols["scores"] == "List<Int>"
    assert result.symbols["profile"] == "Map<String, String>"
    assert result.external_api_used is False
    assert result.network_required is False

def test_typed_assignment_mismatch_is_negative_case() -> None:
    result = AdvancedTypeInferenceEngine().analyze_source('let age: Int = "not an int"\n')
    assert result.ok is False
    assert any(d.code == "PANTHER-TYPE-064-ASSIGN" for d in result.diagnostics)

def test_function_return_mismatch_is_negative_case() -> None:
    result = AdvancedTypeInferenceEngine().analyze_source('fn bad() -> Int { return "wrong" }\n')
    assert result.ok is False
    assert any(d.code == "PANTHER-TYPE-064-RETURN" for d in result.diagnostics)

def test_call_argument_type_mismatch_is_negative_case() -> None:
    src = '''
fn inc(value: Int) -> Int { return value + 1 }
let broken = inc("x")
'''
    result = AdvancedTypeInferenceEngine().analyze_source(src)
    assert result.ok is False
    assert any(d.code == "PANTHER-TYPE-064-ARG" for d in result.diagnostics)

def test_empty_source_fails() -> None:
    with pytest.raises(TypeInferenceError): AdvancedTypeInferenceEngine().analyze_source("   ")

def test_workspace_analysis_uses_phase6_3_workspace(tmp_path: Path) -> None:
    root = tmp_path / "ws"; (root / "core").mkdir(parents=True); (root / "app").mkdir(parents=True)
    (root / "core" / "math.panther").write_text('fn twice(x: Int) -> Int { return x + x }\nlet base = 21\n', encoding="utf-8")
    (root / "app" / "main.panther").write_text('import core\nfn main() -> Int { return 42 }\nlet answer = 42\n', encoding="utf-8")
    (root / "panther.workspace.json").write_text(json.dumps({"name":"phase6_4_ws","version":"0.1.0","entry":"app.main","modules":[{"name":"core","root":"core","sources":["*.panther"]},{"name":"app","root":"app","sources":["*.panther"]}]}), encoding="utf-8")
    report = AdvancedTypeInferenceEngine().analyze_workspace(root)
    assert report["ok"] is True
    assert report["files_analyzed"] == 2
    assert report["external_api_used"] is False
    assert report["network_required"] is False

def test_stress_many_inferences() -> None:
    lines = ["fn add(a: Int, b: Int) -> Int { return a + b }"]
    for i in range(250): lines.append(f"let value_{i} = add({i}, {i + 1})")
    result = AdvancedTypeInferenceEngine().analyze_source("\n".join(lines))
    assert result.ok is True
    assert len(result.symbols) == 250
    assert result.symbols["value_249"] == "Int"
PY64TEST
cat > scripts/run_phase6_4_practical_demo.sh <<'SH64DEMO'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
mkdir -p build/phase6_4_demo_workspace/core build/phase6_4_demo_workspace/app build/reports
cat > build/phase6_4_demo_workspace/core/math.panther <<'PANTHER64'
fn add(a: Int, b: Int) -> Int { return a + b }
fn label(name: String) -> String { return "Hello " + name }
let base = 40
let scores = [1, 2, 3]
PANTHER64
cat > build/phase6_4_demo_workspace/app/main.panther <<'PANTHER64'
import core
let x = 2
let answer = 42
let title = "Panther" + "Lang"
let ready: Bool = true
fn main() -> Int { return 42 }
PANTHER64
cat > build/phase6_4_demo_workspace/panther.workspace.json <<'JSON64'
{"name":"phase6_4_demo_workspace","version":"0.1.0","entry":"app.main","modules":[{"name":"core","root":"core","sources":["*.panther"]},{"name":"app","root":"app","sources":["*.panther"]}]}
JSON64
PYTHONPATH="$ROOT" python3 - <<'PY64RUN'
from language.compiler.type_inference import AdvancedTypeInferenceEngine
report = AdvancedTypeInferenceEngine().analyze_workspace("build/phase6_4_demo_workspace")
print("Phase 6.4 demo ok:", report["ok"]); print("Files analyzed:", report["files_analyzed"]); print("Report: build/reports/phase6_4_last_inference_report.json")
raise SystemExit(0 if report["ok"] else 1)
PY64RUN
SH64DEMO
chmod +x scripts/run_phase6_4_practical_demo.sh
cat > scripts/verify_phase6_4_advanced_type_inference.sh <<'SH64VERIFY'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"; export PYTHONPATH="$ROOT:${PYTHONPATH:-}"; PYTHON_BIN="${PYTHON:-python3}"
echo "== PantherLang Phase 6.4 Professional Verification =="
$PYTHON_BIN - <<'PY64SMOKE'
from language.compiler.type_inference import AdvancedTypeInferenceEngine
result = AdvancedTypeInferenceEngine().analyze_source('fn add(a: Int, b: Int) -> Int { return a + b }\nlet z = add(1, 2)\n')
assert result.ok is True and result.symbols["z"] == "Int" and result.external_api_used is False and result.network_required is False
print("Import/positive smoke: PASS")
PY64SMOKE
if $PYTHON_BIN -m pytest --version >/dev/null 2>&1; then $PYTHON_BIN -m pytest -q tests/phase6_4; else echo "❌ pytest is not installed. Run: python3 -m pip install pytest"; exit 1; fi
scripts/run_phase6_4_practical_demo.sh
$PYTHON_BIN - <<'PY64NEG'
from language.compiler.type_inference import AdvancedTypeInferenceEngine
bad = AdvancedTypeInferenceEngine().analyze_source('let broken: Int = "x"\n')
assert bad.ok is False and any(d.code == "PANTHER-TYPE-064-ASSIGN" for d in bad.diagnostics)
print("Negative test: PASS")
PY64NEG
$PYTHON_BIN - <<'PY64STRESS'
from language.compiler.type_inference import AdvancedTypeInferenceEngine
lines = ['fn add(a: Int, b: Int) -> Int { return a + b }']
for i in range(500): lines.append(f'let stress_{i} = add({i}, {i+1})')
result = AdvancedTypeInferenceEngine().analyze_source('\n'.join(lines))
assert result.ok is True and len(result.symbols) == 500
print("Stress test: PASS")
PY64STRESS
cat > build/reports/phase6_4_verification_summary.json <<'JSON64SUMMARY'
{"phase":"6.4","name":"Advanced Type Inference","version":"0.6.4-advanced-type-inference","status":"passed_when_this_script_exits_zero","external_api_used":false,"network_required":false}
JSON64SUMMARY
echo "✅ Phase 6.4 verification completed successfully."
SH64VERIFY
chmod +x scripts/verify_phase6_4_advanced_type_inference.sh
cat > docs/phase6/PHASE_6_4_ADVANCED_TYPE_INFERENCE.md <<'MD64DOC'
# PantherLang Phase 6.4 — Advanced Type Inference
Phase 6.4 adds deterministic, offline advanced type inference.
Capabilities: literal inference, let inference, typed assignment validation, binary expression inference, list/map inference, function return validation, call arity/argument validation, workspace analysis, JSON reports, practical demo, negative tests, stress tests.
Verify with: `bash scripts/verify_phase6_4_advanced_type_inference.sh`.
MD64DOC
cat > examples/types/phase6_4_advanced_type_inference.panther <<'PANTHER64EX'
fn add(a: Int, b: Int) -> Int { return a + b }
fn greet(name: String) -> String { return "Hello " + name }
let x = 40
let y = 2
let answer = add(x, y)
let title = "Panther" + "Lang"
let ready: Bool = true
let scores = [1, 2, 3]
let labels = {"project": "PantherLang", "phase": "6.4"}
PANTHER64EX
cat >> CHANGELOG.md <<'MD64CHANGE'

## Phase 6.4 — Advanced Type Inference
- Added deterministic advanced type inference engine.
- Added typed/untyped let inference validation.
- Added function return and call argument validation.
- Added collection inference and workspace-level integration.
- Added professional verification, practical demo, negative tests, and stress tests.
MD64CHANGE
cat >> VERSION_PLAN.md <<'MD64VERSION'

### Phase 6.4 — Advanced Type Inference
Status: Implemented locally. Must be verified on target Kali environment.
Version: 0.6.4-advanced-type-inference
MD64VERSION
printf '\nRunning Phase 6.4 verification...\n'
PYTHONPATH="$ROOT:${PYTHONPATH:-}" bash scripts/verify_phase6_4_advanced_type_inference.sh
printf '\n✅ PantherLang Phase 6.4 bootstrap finished.\n'
printf 'Next: review build/reports/phase6_4_verification_summary.json and build/reports/phase6_4_last_inference_report.json\n'
