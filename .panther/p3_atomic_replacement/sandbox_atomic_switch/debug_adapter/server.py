from .launcher import Launcher
from .session import DebugSession
from .event_bus import EventBus
from .event_dispatcher import EventDispatcher
from .execution_dispatcher import ExecutionDispatcher
from .request_dispatcher import RequestDispatcher

class DebugServer:
    def __init__(self):
        self.bus=EventBus()
        self.events=EventDispatcher(self.bus)
        self.session=DebugSession()
        self.launcher=Launcher()
        self.execution=ExecutionDispatcher(self.events)
        self.dispatcher=RequestDispatcher(
            session=self.session,
            events=self.events,
            execution=self.execution
        )

    def dispatch(self, request):
        return self.dispatcher.dispatch(request)
