from .response_dispatcher import ResponseDispatcher
from .server import DebugServer
class RequestDispatcher:
    def __init__(self, server=None, responses=None):
        self.server=server or DebugServer(); self.responses=responses or ResponseDispatcher()
        self.routes={"initialize":self._initialize,"configurationDone":self._configuration_done,"setBreakpoints":self._set_breakpoints,"launch":self._launch,"continue":self._continue,"pause":self._pause,"stop":self._stop,"terminate":self._terminate,"disconnect":self._disconnect}
    def dispatch(self, request):
        if not isinstance(request,dict): return self.responses.error("",request_seq=0,message="request must be a dictionary")
        cmd=request.get("command"); seq=request.get("seq",0)
        if not cmd: return self.responses.error("",request_seq=seq,message="missing DAP command")
        handler=self.routes.get(cmd)
        if handler is None: return self.responses.error(cmd, request_seq=seq, message=f"Unsupported command: {cmd}")
        try: return self.responses.normalize(handler(request.get("arguments",{}) or {}), request_seq=seq, command=cmd)
        except Exception as exc: return self.responses.error(cmd, request_seq=seq, message=str(exc))
    def _initialize(self,args): return self.server.initialize(args)
    def _configuration_done(self,args): return self.server.configuration_done()
    def _set_breakpoints(self,args): return self.server.set_breakpoints(args)
    def _launch(self,args): return self.server.launch(args)
    def _continue(self,args): return self.server.continue_execution(args)
    def _pause(self,args): return self.server.pause(args)
    def _stop(self,args): return self.server.stop(args)
    def _terminate(self,args): return self.server.terminate()
    def _disconnect(self,args): return self.server.disconnect()
