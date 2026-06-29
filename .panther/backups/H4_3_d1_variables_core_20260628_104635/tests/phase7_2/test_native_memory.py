from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_memory_store_set_get_delete() -> None:
    from runtime.memory.memory_store import NativeMemoryStore, PantherMemoryError
    store = NativeMemoryStore()
    store.set("project", "PantherLang")
    assert store.get("project") == "PantherLang"
    assert store.has("project") is True
    store.delete("project")
    assert store.has("project") is False


def test_missing_key_fails() -> None:
    from runtime.memory.memory_store import NativeMemoryStore, PantherMemoryError
    store = NativeMemoryStore()
    try:
        store.get("missing")
        raise AssertionError("missing key should fail")
    except PantherMemoryError:
        pass


def test_memory_api_demo() -> None:
    proc = subprocess.run(
        [sys.executable, "runtime/memory/memory_api.py", "demo"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["demo"] == "native-memory-model"


def test_runtime_context_uses_native_memory() -> None:
    from runtime.ai_runtime.runtime_context import RuntimeContext
    ctx = RuntimeContext(session_id="test")
    ctx.set("x", "y")
    assert ctx.get("x") == "y"
    assert ctx.native_memory.has("x") is True
