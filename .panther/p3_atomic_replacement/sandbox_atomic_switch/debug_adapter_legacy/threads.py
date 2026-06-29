from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from .stack_frames import StackFrameStore, DebugStackFrame


@dataclass(slots=True)
class DebugThread:
    """
    PantherLang professional DAP Thread model.

    DAP Thread fields:
    - id
    - name
    """

    id: int
    name: str = "Main Thread"
    state: str = "running"
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dap(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {
            "id": int(self.id),
            "name": str(self.name),
        }

        if self.metadata:
            payload["metadata"] = dict(self.metadata)

        return payload

    def to_snapshot(self) -> Dict[str, Any]:
        return {
            "id": int(self.id),
            "name": str(self.name),
            "state": str(self.state),
            "metadata": dict(self.metadata),
        }


class ThreadStore:
    """
    H4.3 D5 Thread Store.

    Responsibilities:
    - Own debugger threads.
    - Attach one StackFrameStore per thread.
    - Produce DAP threads response body.
    - Produce DAP stackTrace body for a specific thread.
    """

    def __init__(self) -> None:
        self._threads: Dict[int, DebugThread] = {}
        self._frames_by_thread: Dict[int, StackFrameStore] = {}
        self._next_id = 1

    def create_thread(
        self,
        name: str = "Main Thread",
        state: str = "running",
        metadata: Optional[Dict[str, Any]] = None,
    ) -> DebugThread:
        thread = DebugThread(
            id=self._next_id,
            name=name,
            state=state,
            metadata=dict(metadata or {}),
        )
        self._next_id += 1
        self._threads[thread.id] = thread
        self._frames_by_thread[thread.id] = StackFrameStore()
        return thread

    def ensure_main_thread(self) -> DebugThread:
        if 1 in self._threads:
            return self._threads[1]
        if self._next_id != 1:
            # If custom operations moved next_id, still create deterministic main thread.
            thread = DebugThread(id=1, name="Main Thread", state="running")
            self._threads[1] = thread
            self._frames_by_thread[1] = StackFrameStore()
            self._next_id = max(self._next_id, 2)
            return thread
        return self.create_thread("Main Thread", state="running")

    def has_thread(self, thread_id: int) -> bool:
        return int(thread_id) in self._threads

    def get_thread(self, thread_id: int) -> DebugThread:
        tid = int(thread_id)
        if tid not in self._threads:
            raise KeyError(f"unknown thread id: {tid}")
        return self._threads[tid]

    def frame_store(self, thread_id: int) -> StackFrameStore:
        tid = int(thread_id)
        if tid not in self._frames_by_thread:
            raise KeyError(f"unknown thread frame store: {tid}")
        return self._frames_by_thread[tid]

    def add_frame(
        self,
        thread_id: int,
        name: str,
        source_path: str,
        line: int = 1,
        column: int = 1,
        variables: Optional[Dict[str, Any]] = None,
    ) -> DebugStackFrame:
        self.get_thread(thread_id)
        return self.frame_store(thread_id).create_frame(
            name=name,
            source_path=source_path,
            line=line,
            column=column,
            variables=variables or {},
        )

    def threads(self) -> List[DebugThread]:
        return [self._threads[key] for key in sorted(self._threads.keys())]

    def dap_threads(self) -> List[Dict[str, Any]]:
        return [thread.to_dap() for thread in self.threads()]

    def threads_body(self) -> Dict[str, Any]:
        return {"threads": self.dap_threads()}

    def stack_trace_body(
        self,
        thread_id: int,
        start_frame: int = 0,
        levels: Optional[int] = None,
    ) -> Dict[str, Any]:
        self.get_thread(thread_id)
        return self.frame_store(thread_id).stack_trace_body(
            start_frame=start_frame,
            levels=levels,
        )

    def set_thread_state(self, thread_id: int, state: str) -> DebugThread:
        thread = self.get_thread(thread_id)
        thread.state = str(state)
        return thread

    def remove_thread(self, thread_id: int) -> DebugThread:
        tid = int(thread_id)
        thread = self.get_thread(tid)
        del self._threads[tid]
        self._frames_by_thread.pop(tid, None)
        return thread

    def clear(self) -> None:
        self._threads.clear()
        self._frames_by_thread.clear()

    def snapshot(self) -> Dict[str, Any]:
        return {
            "threadCount": len(self._threads),
            "threads": [thread.to_snapshot() for thread in self.threads()],
            "frameCounts": {
                str(tid): len(store.frames())
                for tid, store in self._frames_by_thread.items()
            },
        }

    def assert_thread_contract(self, thread: Dict[str, Any]) -> bool:
        required = {"id", "name"}
        missing = required.difference(thread.keys())
        if missing:
            raise AssertionError(f"thread missing keys: {sorted(missing)}")
        if not isinstance(thread["id"], int):
            raise AssertionError("thread id must be int")
        return True


class DebugThreadStore(ThreadStore):
    """Public professional alias used by later H4.3 phases."""
    pass
