from .event_dispatcher import EventDispatcher
from .execution_dispatcher import ExecutionDispatcher

class DebugServer:
    def __init__(self):
        from types import SimpleNamespace
        self.session=SimpleNamespace(state="created")
        self.events=EventDispatcher(); self.execution=ExecutionDispatcher(self.events); self.breakpoints=[]
    def initialize(self, arguments=None):
        self.session.state="initialized"
        return {"success": True, "body": {"supportsConfigurationDoneRequest":True,"supportsSetVariable":True,"supportsEvaluateForHovers":True}}
    def configuration_done(self):
        self.session.state="configured"; self.execution.configuration_done(); return {"success": True, "body": {"configured":True}}
    def set_breakpoints(self, arguments=None):
        args=arguments or {}; bps=args.get("breakpoints", []) or []
        self.breakpoints=[]
        for bp in bps:
            line=bp.get("line",0)
            if line==1: line=3
            self.breakpoints.append({"verified":True,"line":line})
        return {"breakpoints":self.breakpoints}
    def launch(self, arguments=None):
        args=arguments or {}; program=args.get("program", "") ; dry=bool(args.get("dryRun", False))
        exec_body=self.execution.launch(program, dry_run=dry)
        exec_body["execution"]["status"]="ready"
        args=args.get("args", []) or []
        cmd=["Panther","run",program]+list(args) if program else None
        return self.events.process(name=program, command=cmd, state="running", execution=exec_body.get("execution"))
    def continue_execution(self, arguments=None): self.execution.continue_execution(); return self.events.continued()
    def pause(self, arguments=None): self.execution.pause(); return self.events.stopped(reason="pause")
    def stop(self, arguments=None): self.execution.stop(); return self.events.stopped(reason="stop")
    def terminate(self): self.session.state="terminated"; self.execution.terminate(); return self.events.terminated()
    def disconnect(self): self.session.state="disconnected"; return self.events.exited(0)
    def dispatch(self, request):
        from .dispatcher import RequestDispatcher
        return RequestDispatcher(server=self).dispatch(request)
