from dataclasses import dataclass
from .stack_frames import StackFrameStore
@dataclass
class DebugThread:
    id:int; name:str; state:str="running"
    def to_dap(self): return {"id":self.id,"name":self.name}
class ThreadStore:
    def __init__(self): self._next=1; self.threads={}; self.frames={}
    def create_thread(self,name,state="running"):
        t=DebugThread(self._next,name,state); self._next+=1; self.threads[t.id]=t; self.frames[t.id]=StackFrameStore(); return t
    def ensure_main_thread(self):
        if not self.threads: return self.create_thread("Main Thread")
        return self.threads[min(self.threads)]
    def has_thread(self,id): return id in self.threads
    def get_thread(self,id):
        if id not in self.threads: raise KeyError(id)
        return self.threads[id]
    def remove_thread(self,id):
        t=self.get_thread(id); del self.threads[id]; self.frames.pop(id,None); return t
    def clear(self): self.threads.clear(); self.frames.clear()
    def frame_store(self,id): self.get_thread(id); return self.frames[id]
    def add_frame(self,thread_id,name,source_path,line=1,column=1,variables=None): return self.frame_store(thread_id).create_frame(name,source_path,line,column,variables or {})
    def set_thread_state(self,id,state): self.get_thread(id).state=state
    def stack_trace_body(self,id): return self.frame_store(id).stack_trace_body()
    def threads_body(self): return {"threads":[t.to_dap() for t in self.threads.values()]}
    def assert_thread_contract(self,p): return "id" in p and "name" in p
    def snapshot(self): return {"threadCount":len(self.threads),"threads":[{**t.to_dap(),"state":t.state} for t in self.threads.values()]}
