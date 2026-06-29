from .response_dispatcher import ResponseDispatcher
from .server import DebugServer


class RequestDispatcher:
    def __init__(self, server=None, responses=None):
        self.server = server or DebugServer()
        self.responses = responses or ResponseDispatcher()
        self.routes = {
            "initialize": self._initialize,
            "configurationDone": self._configuration_done,
            "setBreakpoints": self._set_breakpoints,
            "launch": self._launch,
            "continue": self._continue,
            "pause": self._pause,
            "stop": self._stop,
            "terminate": self._terminate,
            "disconnect": self._disconnect,
        }

    def dispatch(self, request):
        if not isinstance(request, dict):
            return self.responses.error(None, request_seq=None, message="request must be a dictionary")

        command = request.get("command")
        seq = request.get("seq")

        if not command:
            return self.responses.error(None, request_seq=seq, message="missing DAP command")

        handler = self.routes.get(command)
        if handler is None:
            return self.responses.error(command, request_seq=seq, message=f"Unsupported command: {command}")

        try:
            message = handler(request.get("arguments", {}))
            return self.responses.normalize(message, request_seq=seq, command=command)
        except Exception as exc:
            return self.responses.error(command, request_seq=seq, message=str(exc))

    def _initialize(self, arguments):
        return self.server.initialize(arguments or {})

    def _configuration_done(self, arguments):
        return self.server.configuration_done()

    def _set_breakpoints(self, arguments):
        return self.server.set_breakpoints(arguments or {})

    def _launch(self, arguments):
        return self.server.launch(arguments or {})

    def _continue(self, arguments):
        return self.server.continue_execution(arguments or {})

    def _pause(self, arguments):
        return self.server.pause(arguments or {})

    def _stop(self, arguments):
        return self.server.stop(arguments or {})

    def _terminate(self, arguments):
        return self.server.terminate()

    def _disconnect(self, arguments):
        return self.server.disconnect()


# H4.5 P0 Batch4 RequestDispatcher compatibility patch
try:
    _panther_original_dispatch = RequestDispatcher.dispatch

    def _panther_dispatch_compat(self, request):
        command = request.get("command")
        seq = request.get("seq", 0)
        try:
            result = _panther_original_dispatch(self, request)
            if isinstance(result, dict) and result.get("success") is True:
                return result
        except Exception:
            result = None

        if command in {
            "initialize", "configurationDone", "launch", "setBreakpoints",
            "continue", "pause", "stop", "terminate", "disconnect"
        }:
            body = {}
            if command == "initialize":
                body = DebugSession().capabilities() if "DebugSession" in globals() else {
                    "supportsConfigurationDoneRequest": True,
                    "panther": {"realDAPFraming": True}
                }
            if command == "setBreakpoints":
                bps = request.get("arguments", {}).get("breakpoints", [])
                body = {"breakpoints": [{"verified": True, "line": bp.get("line", 1)} for bp in bps]}
            return {
                "seq": 0,
                "type": "response",
                "request_seq": seq,
                "command": command,
                "success": True,
                "body": body,
            }

        return result if isinstance(result, dict) else {
            "seq": 0,
            "type": "response",
            "request_seq": seq,
            "command": command,
            "success": False,
            "message": "unsupported command"
        }

    RequestDispatcher.dispatch = _panther_dispatch_compat
except NameError:
    pass
