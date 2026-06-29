from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"

def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)

def test_demo_compiler() -> None:
    code, data = run_cmd("demo")
    assert code == 0
    assert data["ok"] is True
    assert data["phase"] == "6.10"
    assert "lex" in data["stages"]
    assert data["external_api_used"] is False

def test_compile_example(tmp_path: Path) -> None:
    out = tmp_path / "hello.sh"
    code, data = run_cmd("compile", "examples/phase6_final/hello_phase6_10.panther", "--out", str(out))
    assert code == 0
    assert data["ok"] is True
    assert out.exists()
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert "Phase 6.10 compiler integration works" in proc.stdout

def test_negative_empty() -> None:
    code, data = run_cmd("negative", "--case", "empty")
    assert code == 2
    assert data["ok"] is False
    assert "Source cannot be empty" in data["error"]

def test_negative_unsupported() -> None:
    code, data = run_cmd("negative", "--case", "unsupported")
    assert code == 2
    assert data["ok"] is False
    assert "Unsupported statement" in data["error"]
