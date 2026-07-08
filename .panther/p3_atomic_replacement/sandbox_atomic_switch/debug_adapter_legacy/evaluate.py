from dataclasses import dataclass
from types import SimpleNamespace
@dataclass
class EvaluateResult:
    result:str; type_name:str; variables_reference:int=0; metadata:dict|None=None
    def to_dap_body(self):
        d={"result":self.result,"type":self.type_name,"variablesReference":self.variables_reference}
        if self.metadata is not None: d["metadata"]=self.metadata
        return d
class EvaluateEngine:
    def __init__(self, symbols=None): self.context=SimpleNamespace(scope_store=None); self.symbols=symbols or {}
    def _literal(self,expr):
        e=expr.strip()
        if e=="": return EvaluateResult("","string",0,{"empty":True}).to_dap_body()
        if e.startswith('"') and e.endswith('"') and len(e)>=2: return EvaluateResult(e[1:-1],"string").to_dap_body()
        if e in ("true","false"): return EvaluateResult(e,"bool").to_dap_body()
        if e=="null": return EvaluateResult("null","null").to_dap_body()
        try:
            if "." in e: float(e); return EvaluateResult(e,"float").to_dap_body()
            int(e); return EvaluateResult(e,"int").to_dap_body()
        except Exception: return None
    def evaluate_body(self,expression,frame_id=None,variables_reference=None):
        lit=self._literal(expression or "")
        if lit is not None: return lit
        scope_store=getattr(self.context,"scope_store",None)
        name=(expression or "").strip()
        if scope_store is not None:
            vars=[]
            if variables_reference is not None: vars=scope_store.variables_for_scope_reference(variables_reference)
            elif frame_id is not None:
                body=scope_store.scopes_body(frame_id); refs=[s["variablesReference"] for s in body["scopes"]]
                for r in refs: vars.extend(scope_store.variables_for_scope_reference(r))
            for v in vars:
                if v.get("name")==name:
                    out={"result":v.get("value",""),"type":v.get("type",""),"variablesReference":v.get("variablesReference",0),"metadata":{"source":"variable","name":name}}
                    return out
        if name and name.isidentifier(): return EvaluateResult(f"<unresolved: {name}>","unresolved",0).to_dap_body()
        return EvaluateResult(f"<expression: {name}>","expression",0).to_dap_body()
    def assert_evaluate_body_contract(self,body): return all(k in body for k in ("result","type","variablesReference"))

class _EvalObject:
    def __init__(self, result): self.result=str(result)
def _eval_expr(self, expr):
    try:
        return _EvalObject(eval(expr, {"__builtins__": {}}, dict(self.symbols)))
    except Exception:
        return _EvalObject("")
EvaluateEngine.evaluate = _eval_expr
