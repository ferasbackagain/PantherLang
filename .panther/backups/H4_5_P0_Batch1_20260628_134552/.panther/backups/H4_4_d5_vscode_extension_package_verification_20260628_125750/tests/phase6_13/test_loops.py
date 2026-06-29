from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_for_loop_demo(tmp_path: Path) -> None:
    out = tmp_path / "loop.sh"
    code, data = run_cmd("compile", "examples/phase6_loops/for_loop_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert proc.stdout.count("Loop iteration") == 3
def test_bad_loop_range(tmp_path: Path) -> None:
    src = tmp_path / "bad_loop.panther"
    src.write_text("for i in 5..1 {\n    print i\n}\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
