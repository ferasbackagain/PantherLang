from dataclasses import dataclass

@dataclass
class DebugThread:
    id: int
    name: str

class ThreadStore:
    def __init__(self):
        self._threads = [DebugThread(1, "main")]

    def list(self):
        return list(self._threads)

    def main(self):
        return self._threads[0]
