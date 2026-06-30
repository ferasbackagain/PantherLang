from dataclasses import dataclass
from .stack_frames import StackFrameStore

@dataclass
class DebugThread:
    id: int
    name: str
    state: str = "running"

    def to_dap(self):
        return {"id": self.id, "name": self.name}

class ThreadStore:
    def __init__(self):
        self._threads = []
        self._frames = {}
        self._next = 1

    def create_thread(self, name="Main Thread", state="running"):
        t = DebugThread(self._next, name, state)
        self._next += 1
        self._threads.append(t)
        self._frames[t.id] = StackFrameStore()
        return t

    def ensure_main_thread(self):
        return self._threads[0] if self._threads else self.create_thread("Main Thread")

    def main(self):
        return self.ensure_main_thread()

    def list(self):
        return list(self._threads)

    def threads_body(self):
        return {"threads": [t.to_dap() for t in self._threads]}

    def frame_store(self, thread_id):
        if thread_id not in self._frames:
            raise KeyError(thread_id)
        return self._frames[thread_id]

    def add_frame(self, thread_id, name, source_path="main.pan", line=1, column=1, variables=None):
        return self.frame_store(thread_id).create_frame(name, source_path, line, column, variables)

    def stack_trace_body(self, thread_id, start_frame=0, levels=None):
        return self.frame_store(thread_id).stack_trace_body(start_frame, levels)

    def set_thread_state(self, thread_id, state):
        for t in self._threads:
            if t.id == thread_id:
                t.state = state
                return t
        raise KeyError(thread_id)

    def snapshot(self):
        return {"threadCount": len(self._threads), "threads": [{"id": t.id, "name": t.name, "state": t.state} for t in self._threads]}

    def remove_thread(self, thread_id):
        for i, t in enumerate(self._threads):
            if t.id == thread_id:
                self._frames.pop(thread_id, None)
                return self._threads.pop(i)
        raise KeyError(thread_id)

    def clear(self):
        self._threads.clear()
        self._frames.clear()

    def assert_thread_contract(self, item):
        return isinstance(item, dict) and "id" in item and "name" in item
