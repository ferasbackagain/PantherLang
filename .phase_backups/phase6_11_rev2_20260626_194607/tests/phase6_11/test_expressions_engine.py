from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"


def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)


def test_expression_demo_compile_and_run(tmp_path: Path) -> None:
    out = tmp_path / "expr.sh"
    code, data = run_cmd("compile", "examples/phase6_expressions/expressions_demo.panther", "--out", str(out))
    assert code == 0
    assert data["ok"] is True
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert "15" in proc.stdout
    assert "30" in proc.stdout
    assert "true" in proc.stdout


def test_division_by_zero_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad.panther"
    src.write_text("let x = 10 / 0\nprint x\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
    assert "Division by zero" in data["error"]


def test_undefined_symbol_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad_symbol.panther"
    src.write_text("print missing_value\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad_symbol.sh"))
    assert code == 2
    assert data["ok"] is False
    assert "Undefined symbol" in data["error"]
