class ExecutionMergeEngine:
    def __init__(self): self.state="created"; self.execution={"running":False}
    def _body(self, **kw):
        self.execution.update(kw.get("execution",{})); return {"state":self.state,"execution":dict(self.execution), **{k:v for k,v in kw.items() if k!="execution"}}
    def configuration_done(self): self.state="configured"; return {"configured":True,"state":self.state,"execution":dict(self.execution)}
    def set_breakpoints(self, breakpoints): return {"breakpoints":[{"verified":True,"line":bp.get("line",0)} for bp in (breakpoints or [])]}
    def launch(self, program, dry_run=False):
        self.state="running"; self.execution={"launched":True,"running":True,"paused":False,"stopped":False,"terminated":False,"program":program,"dryRun":dry_run}
        return {"state":self.state,"threadId":1,"execution":dict(self.execution)}
    def pause(self): self.state="paused"; self.execution.update({"paused":True,"running":False}); return {"state":self.state,"execution":dict(self.execution)}
    def continue_execution(self): self.state="running"; self.execution.update({"running":True,"paused":False}); return {"state":self.state,"execution":dict(self.execution)}
    def stop(self): self.state="stopped"; self.execution.update({"stopped":True,"running":False}); return {"state":self.state,"execution":dict(self.execution)}
    def terminate(self): self.state="terminated"; self.execution.update({"terminated":True,"running":False}); return {"state":self.state,"execution":dict(self.execution)}
    def current(self): return {"state":self.state,"execution":dict(self.execution)}
    def assert_execution_contract(self, body): return isinstance(body,dict) and "state" in body and "execution" in body
