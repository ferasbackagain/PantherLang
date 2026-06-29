from __future__ import annotations

"""H4.3 compatibility facade for PantherLang debug adapter variables.

This module preserves the historical import path `debug_adapter.variables` while
forwarding to the canonical split modules introduced during P-2/P-3.
"""

try:
    from .variables_core import *  # noqa: F401,F403
except Exception:  # pragma: no cover
    pass
try:
    from .variable_store import VariableStore  # noqa: F401
except Exception:  # pragma: no cover
    VariableStore = None  # type: ignore
try:
    from .variable_references import VariableReferenceStore  # noqa: F401
except Exception:  # pragma: no cover
    VariableReferenceStore = None  # type: ignore
