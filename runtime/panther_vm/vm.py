from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PantherRuntimeResult:
    ok: bool
    output: str
    exit_code: int = 0


class PantherVM:
    """Minimal runtime VM contract scaffold for R3 Batch 2.

    This is not the final interpreter. It defines the execution boundary used by
    later lexer/parser/AST stages.
    """

    def execute_source(self, source: str) -> PantherRuntimeResult:
        if not isinstance(source, str):
            raise TypeError("source must be a string")
        return PantherRuntimeResult(
            ok=True,
            output="PantherVM scaffold accepted source",
            exit_code=0,
        )
