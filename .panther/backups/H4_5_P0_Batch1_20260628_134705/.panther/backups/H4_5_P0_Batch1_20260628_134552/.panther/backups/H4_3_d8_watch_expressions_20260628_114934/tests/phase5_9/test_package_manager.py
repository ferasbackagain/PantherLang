from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "packages" / "runtime" / "package_manager.py"

def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(RUNTIME), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)

def test_demo_package_manager() -> None:
    code, data = run_cmd("--registry", "/tmp/panther_phase5_9_pytest_registry", "demo")
    assert code == 0
    assert data["ok"] is True
    assert data["integrity_verified"] is True
    assert data["signature_verified"] is True
    assert data["network_used"] is False

def test_missing_package_fails() -> None:
    code, data = run_cmd("--registry", "/tmp/panther_phase5_9_missing_registry", "negative", "--case", "missing")
    assert code == 2
    assert "Package not found" in data["error"]

def test_bad_kind_fails() -> None:
    code, data = run_cmd("--registry", "/tmp/panther_phase5_9_bad_kind_registry", "negative", "--case", "bad-kind")
    assert code == 2
    assert "Invalid package kind" in data["error"]

def test_tamper_fails() -> None:
    code, data = run_cmd("--registry", "/tmp/panther_phase5_9_tamper_registry", "negative", "--case", "tamper")
    assert code == 2
    assert "integrity mismatch" in data["error"]
