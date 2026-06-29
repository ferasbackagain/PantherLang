from .variables_core import DebugVariable, VariableFactory, VariablesCore
from .variable_references import (
    ReferenceEntry,
    VariableReferenceAllocator,
    VariableReferenceResolver,
    VariableReferenceService,
)

__all__ = [
    "DebugVariable",
    "VariableFactory",
    "VariablesCore",
    "ReferenceEntry",
    "VariableReferenceAllocator",
    "VariableReferenceResolver",
    "VariableReferenceService",
]
