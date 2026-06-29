from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_stdlib_demo(tmp_path: Path) -> None:
    out = tmp_path / "stdlib.sh"
    code, data = run_cmd("compile", "examples/phase6_stdlib/stdlib_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert "PANTHER" in proc.stdout
    assert "15" in proc.stdout
    assert "21" in proc.stdout
def test_bad_stdlib_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad_stdlib.panther"
    src.write_text("print std.crypto.hash(\"x\")\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
