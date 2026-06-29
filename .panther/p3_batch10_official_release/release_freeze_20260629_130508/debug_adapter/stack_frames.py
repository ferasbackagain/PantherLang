from dataclasses import dataclass

@dataclass
class DebugStackFrame:
    id: int
    name: str
    line: int
    column: int = 1
    source: dict | None = None

class StackFrameStore:
    def __init__(self):
        self._frames = []

    def push(self, name, line=1, source_path="main.pan"):
        frame = DebugStackFrame(
            id=len(self._frames)+1,
            name=name,
            line=line,
            source={"path": source_path},
        )
        self._frames.append(frame)
        return frame

    def list(self):
        return list(self._frames)

    def clear(self):
        self._frames.clear()
