from enum import Enum


class SessionState(str, Enum):
    CREATED = "created"
    INITIALIZED = "initialized"
    CONFIGURED = "configured"
    LAUNCHED = "launched"
    RUNNING = "running"
    TERMINATED = "terminated"
    DISCONNECTED = "disconnected"


class InvalidStateTransition(RuntimeError):
    pass


class SessionStateMachine:
    VALID_TRANSITIONS = {
        SessionState.CREATED: {SessionState.INITIALIZED, SessionState.DISCONNECTED},
        SessionState.INITIALIZED: {SessionState.CONFIGURED, SessionState.LAUNCHED, SessionState.DISCONNECTED},
        SessionState.CONFIGURED: {SessionState.LAUNCHED, SessionState.DISCONNECTED},
        SessionState.LAUNCHED: {SessionState.RUNNING, SessionState.TERMINATED, SessionState.DISCONNECTED},
        SessionState.RUNNING: {SessionState.TERMINATED, SessionState.DISCONNECTED},
        SessionState.TERMINATED: {SessionState.DISCONNECTED},
        SessionState.DISCONNECTED: set(),
    }

    def __init__(self):
        self.state = SessionState.CREATED

    def transition(self, next_state):
        next_state = SessionState(next_state)
        if next_state not in self.VALID_TRANSITIONS[self.state]:
            raise InvalidStateTransition(f"invalid transition: {self.state.value} -> {next_state.value}")
        self.state = next_state
        return self.state

    def is_terminal(self):
        return self.state in {SessionState.TERMINATED, SessionState.DISCONNECTED}
