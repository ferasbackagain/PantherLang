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


# P-3 Batch 7.5 compatibility contract: historical H4.3 tests expect
# ThreadStore.ensure_main_thread() to return/create the canonical main thread.
def _p75_thread_store_ensure_main_thread(self):
    if hasattr(self, "main"):
        return self.main()
    if not hasattr(self, "_threads") or not self._threads:
        try:
            self._threads = [DebugThread(1, "main")]
        except NameError:
            self._threads = []
    return self._threads[0] if self._threads else None

try:
    ThreadStore.ensure_main_thread = _p75_thread_store_ensure_main_thread
except NameError:
    pass
