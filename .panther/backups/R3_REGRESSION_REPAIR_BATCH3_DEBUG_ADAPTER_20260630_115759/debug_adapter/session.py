from dataclasses import dataclass, field

@dataclass
class DebugSession:
    state: str = "created"
    initialized: bool = False
    _capabilities: dict = field(default_factory=lambda:{
        "supportsConfigurationDoneRequest": True,
        "supportsSetVariable": True,
        "supportsEvaluateForHovers": True,
        "supportsTerminateRequest": True,
        "panther":{
            "realDAPFraming":True,
            "adapter":"pantherlang",
            "protocol":"DAP"
        }
    })
    initialize_args: dict = field(default_factory=dict)

    def apply_initialize_arguments(self, arguments):
        self.initialize_args=dict(arguments or {})
        self.initialized=True
        self.state="initialized"

    def capabilities(self):
        return dict(self._capabilities)

    def configuration_done(self):
        self.state="configured"

    def launch(self, program=None, args=None, cwd=None):
        self.state="running"
        return {"state":self.state,"program":program,"args":args or [],"cwd":cwd}

    def terminate(self):
        self.state="terminated"

    def disconnect(self):
        self.state="disconnected"
