"""PantherLang Debug Adapter variables compatibility facade.

This module intentionally exports both the newer production services and the
legacy names used by H4/H4.2/H4.3 regression suites. Do not collapse these
imports into private-only modules; tests and extension integration import from
``debug_adapter.variables`` as a public API surface.
"""

from .variables_core import DebugVariable, VariableFactory, VariablesCore
from .variable_references import (
    ReferenceEntry,
    VariableReferenceAllocator,
    VariableReferenceResolver,
    VariableReferenceService,
)
from .variable_store import VariableScopeRecord, VariableStore, DebugVariableStore
from .stack_frames import StackFrameSource, DebugStackFrame, StackFrameStore
from .threads import DebugThread, ThreadStore, DebugThreadStore
from .scopes import DebugScope, ScopeStore, DebugScopeStore
from .evaluate import EvaluateResult, EvaluateContext, EvaluateEngine, DebugEvaluateEngine
from .watch_expressions import (
    WatchExpression,
    WatchExpressionStore,
    WatchExpressionManager,
    build_watch_manager_for_thread_store,
)

__all__ = [
    "DebugVariable",
    "VariableFactory",
    "VariablesCore",
    "ReferenceEntry",
    "VariableReferenceAllocator",
    "VariableReferenceResolver",
    "VariableReferenceService",
    "VariableScopeRecord",
    "VariableStore",
    "DebugVariableStore",
    "StackFrameSource",
    "DebugStackFrame",
    "StackFrameStore",
    "DebugThread",
    "ThreadStore",
    "DebugThreadStore",
    "DebugScope",
    "ScopeStore",
    "DebugScopeStore",
    "EvaluateResult",
    "EvaluateContext",
    "EvaluateEngine",
    "DebugEvaluateEngine",
    "WatchExpression",
    "WatchExpressionStore",
    "WatchExpressionManager",
    "build_watch_manager_for_thread_store",
]
