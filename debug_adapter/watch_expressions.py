from dataclasses import dataclass
from .evaluate import EvaluateEngine
@dataclass
class WatchExpression:
    id:int; expression:str; frame_id:int|None=None; enabled:bool=True; last_result:dict|None=None
    def to_dap(self): return {"id":self.id,"expression":self.expression,"frameId":self.frame_id,"enabled":self.enabled}
class WatchExpressionStore:
    def __init__(self,evaluate_engine=None): self.evaluate_engine=evaluate_engine or EvaluateEngine(); self._next=1; self.items={}
    def add(self,expression,frame_id=None):
        w=WatchExpression(self._next,expression,frame_id); self._next+=1; self.items[w.id]=w; return w
    def get(self,id):
        if id not in self.items: raise KeyError(id)
        return self.items[id]
    def list(self): return list(self.items.values())
    def snapshot(self): return {"watchCount":len(self.items),"watchExpressions":[w.to_dap() for w in self.list()]}
    def assert_watch_contract(self,p): return "id" in p and "expression" in p
    def evaluate_one(self,id):
        w=self.get(id)
        if not w.enabled:
            res={"result":"<disabled>","type":"disabled","variablesReference":0,"metadata":{"watchId":w.id,"enabled":False}}
        else:
            res=self.evaluate_engine.evaluate_body(w.expression, frame_id=w.frame_id)
            res.setdefault("metadata",{}); res["metadata"].update({"watchId":w.id,"enabled":True})
        w.last_result=res; return res
    def evaluate_all(self): return [self.evaluate_one(w.id) for w in self.list()]
    def disable(self,id): self.get(id).enabled=False
    def enable(self,id): self.get(id).enabled=True
    def update_expression(self,id,expression): w=self.get(id); w.expression=expression; w.last_result=None; return w
    def remove(self,id): w=self.get(id); del self.items[id]; return w
    def clear(self): self.items.clear()
class WatchExpressionManager(WatchExpressionStore): pass
def build_watch_manager_for_thread_store(thread_store): return WatchExpressionManager()
