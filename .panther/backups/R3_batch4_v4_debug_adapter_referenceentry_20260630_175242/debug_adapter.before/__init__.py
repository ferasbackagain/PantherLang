"""PantherLang Debug Adapter Protocol core package."""

__version__ = "0.4.1-batch4-compat"

from .adapter import PantherDebugAdapter
from .session import DebugSession
from .launcher import LaunchResult, Launcher, PantherProgramLauncher
from .server import DebugServer
from .dispatcher import RequestDispatcher
from .variables import (
    DebugVariable,
    VariableFactory,
    VariablesCore,
    VariableReferenceService,
    VariableStore,
    DebugVariableStore,
    StackFrameStore,
    ThreadStore,
    ScopeStore,
    EvaluateEngine,
    WatchExpressionStore,
)

__all__ = [
    "PantherDebugAdapter",
    "DebugSession",
    "LaunchResult",
    "Launcher",
    "PantherProgramLauncher",
    "DebugServer",
    "RequestDispatcher",
    "DebugVariable",
    "VariableFactory",
    "VariablesCore",
    "VariableReferenceService",
    "VariableStore",
    "DebugVariableStore",
    "StackFrameStore",
    "ThreadStore",
    "ScopeStore",
    "EvaluateEngine",
    "WatchExpressionStore",
    "__version__",
]
