from dataclasses import dataclass, field
from typing import Any, Dict, Optional

from .capabilities import default_capabilities
from .state_machine import SessionState, SessionStateMachine


@dataclass
class DebugSession:
    def capabilities(self):
        return {
            "supportsConfigurationDoneRequest": True,
            "supportsSetVariable": True,
            "supportsEvaluateForHovers": True,
            "supportsTerminateRequest": True,
            "supportsStepInTargetsRequest": False,
            "supportsStepBack": False,
            "supportsRestartRequest": False,
            "panther": {
                "realDAPFraming": True,
                "adapter": "pantherlang",
                "protocol": "DAP"
            }
        }


    def apply_initialize_arguments(self, arguments):
        """Apply DAP initialize arguments."""
        self.initialize_arguments = dict(arguments or {})
        self.client_id = self.initialize_arguments.get("clientID")
        self.adapter_id = self.initialize_arguments.get("adapterID", "pantherlang")
        self.initialized = True
        return self.capabilities()


    def __post_init__(self):
        self.machine = SessionStateMachine()

    @property
    def state(self):
        return self.machine.state.value

    def initialize(self, client_capabilities=None):
        self.client_capabilities = client_capabilities or {}
        self.machine.transition(SessionState.INITIALIZED)
        return self.capabilities

    def configuration_done(self):
        if self.machine.state == SessionState.INITIALIZED:
            self.machine.transition(SessionState.CONFIGURED)
        return True

    def launch(self, program, args=None, cwd=None):
        self.program = program
        self.args = list(args or [])
        self.cwd = cwd
        if self.machine.state == SessionState.INITIALIZED:
            self.machine.transition(SessionState.LAUNCHED)
        elif self.machine.state == SessionState.CONFIGURED:
            self.machine.transition(SessionState.LAUNCHED)
        else:
            self.machine.transition(SessionState.LAUNCHED)
        self.machine.transition(SessionState.RUNNING)
        return {
            "program": self.program,
            "args": self.args,
            "cwd": self.cwd,
            "state": self.state,
        }

    def terminate(self):
        if self.machine.state.value not in {"terminated", "disconnected"}:
            self.machine.transition(SessionState.TERMINATED)
        return self.state

    def disconnect(self):
        if self.machine.state.value != "disconnected":
            if self.machine.state.value not in {"terminated"}:
                try:
                    self.machine.transition(SessionState.TERMINATED)
                except Exception:
                    pass
            self.machine.transition(SessionState.DISCONNECTED)
        return self.state
