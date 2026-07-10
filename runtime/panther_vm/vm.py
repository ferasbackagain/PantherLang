from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class PantherRuntimeResult:
    ok: bool
    output: str
    exit_code: int = 0


class PantherVM:
    def execute_source(self, source: str) -> PantherRuntimeResult:
        if not isinstance(source, str):
            raise TypeError("source must be a string")
        try:
            from compiler.runtime.execution_pipeline import execute_source
            result = execute_source(source)
            output = "\n".join(result.captured_output) if result.captured_output else ""
            if result.error:
                return PantherRuntimeResult(ok=False, output=result.error, exit_code=1)
            return PantherRuntimeResult(ok=True, output=output, exit_code=0)
        except Exception as e:
            return PantherRuntimeResult(ok=False, output=str(e), exit_code=1)
