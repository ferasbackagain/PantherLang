from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "compiler" / "ai_optimizer" / "runtime" / "ai_optimizer.py"

def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(RUNTIME), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)

def test_demo_optimizer() -> None:
    code, data = run_cmd("demo")
    assert code == 0
    assert data["ok"] is True
    assert "let x = 14" in data["optimized_source"]
    assert "print 14" in data["optimized_source"]
    assert 'print ""' not in data["optimized_source"]

def test_negative_empty() -> None:
    code, data = run_cmd("negative", "--case", "empty")
    assert code == 2
    assert data["ok"] is False
    assert "Source cannot be empty" in data["error"]

def test_negative_unbalanced() -> None:
    code, data = run_cmd("negative", "--case", "unbalanced")
    assert code == 2
    assert data["ok"] is False
    assert "unbalanced braces" in data["error"]

def test_negative_unsafe() -> None:
    code, data = run_cmd("negative", "--case", "unsafe")
    assert code == 2
    assert data["ok"] is False
    assert "Unsafe optimizer marker blocked" in data["error"]
