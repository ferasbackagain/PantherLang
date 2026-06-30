from dataclasses import dataclass, field

@dataclass
class PantherCompiledProgram:
    source: str
    ir: object = None
    diagnostics: list = field(default_factory=list)
    output: str = ""

class PantherEndToEndCompiler:
    def compile_source(self, source: str):
        return PantherCompiledProgram(
            source=source,
            ir={"source": source, "stage": "compat-e2e"},
            diagnostics=[],
            output=source,
        )
