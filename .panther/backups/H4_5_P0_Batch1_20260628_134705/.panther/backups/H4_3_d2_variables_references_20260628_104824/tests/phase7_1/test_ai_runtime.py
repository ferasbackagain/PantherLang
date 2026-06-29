from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_runtime_lifecycle() -> None:
    from runtime.ai_runtime.ai_runtime import PantherAIRuntime
    runtime = PantherAIRuntime()
    status = runtime.initialize()
    assert status["started"] is True
    result = runtime.execute("test")
    assert result["ok"] is True
    assert result["result"] == "executed:test"
    stopped = runtime.shutdown()
    assert stopped["started"] is False


def test_runtime_empty_instruction_fails() -> None:
    from runtime.ai_runtime.ai_runtime import PantherAIRuntime, PantherAIRuntimeError
    runtime = PantherAIRuntime()
    runtime.initialize()
    try:
        runtime.execute("")
        raise AssertionError("empty instruction should fail")
    except PantherAIRuntimeError:
        pass


def test_runtime_api_demo() -> None:
    proc = subprocess.run(
        [sys.executable, "runtime/ai_runtime/runtime_api.py", "demo"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["demo"] == "ai-runtime-foundation"
