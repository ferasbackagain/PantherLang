from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "distributed" / "runtime" / "distributed_runtime.py"

def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(RUNTIME), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)

def test_demo_distributed_runtime() -> None:
    code, data = run_cmd("demo")
    assert code == 0
    assert data["ok"] is True
    assert data["completed_tasks"] == 3
    assert data["failed_tasks"] == 0
    assert data["network_used"] is False

def test_stress_runtime() -> None:
    code, data = run_cmd("stress", "--count", "50")
    assert code == 0
    assert data["ok"] is True
    assert data["scheduled_tasks"] == 50
    assert data["completed_tasks"] == 50

def test_missing_capability_fails() -> None:
    code, data = run_cmd("negative", "--case", "missing-capability")
    assert code == 2
    assert data["ok"] is False
    assert "Missing required node capability" in data["error"]

def test_bad_node_fails() -> None:
    code, data = run_cmd("negative", "--case", "bad-node")
    assert code == 2
    assert data["ok"] is False
    assert "Node id cannot be empty" in data["error"]
