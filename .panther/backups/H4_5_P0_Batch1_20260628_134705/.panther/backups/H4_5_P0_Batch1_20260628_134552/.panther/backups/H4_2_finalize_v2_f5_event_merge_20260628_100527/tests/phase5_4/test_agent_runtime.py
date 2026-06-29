from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "agents" / "runtime" / "agent_runtime.py"


def run_cmd(*args: str):
    proc = subprocess.run(
        [sys.executable, str(RUNTIME), *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    return proc.returncode, json.loads(proc.stdout)


def test_demo_workflow() -> None:
    code, data = run_cmd("demo")
    assert code == 0
    assert data["ok"] is True
    assert data["agents_executed"] == 3
    assert data["messages_exchanged"] == 3
    assert data["security_violations"] == 0
    assert data["external_api_used"] is False


def test_stress_messages() -> None:
    code, data = run_cmd("stress", "--count", "25")
    assert code == 0
    assert data["ok"] is True
    assert data["stress_messages"] == 25
    assert data["messages_exchanged"] == 25


def test_unregistered_agent_fails() -> None:
    code, data = run_cmd("negative", "--case", "unregistered")
    assert code == 2
    assert data["ok"] is False
    assert "Unregistered agent" in data["error"]
    assert data["security_violations"] >= 1


def test_permission_fails() -> None:
    code, data = run_cmd("negative", "--case", "permission")
    assert code == 2
    assert data["ok"] is False
    assert "lacks permission" in data["error"]
    assert data["security_violations"] >= 1
