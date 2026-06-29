from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_struct_demo(tmp_path: Path) -> None:
    out = tmp_path / "struct.sh"
    code, data = run_cmd("compile", "examples/phase6_structs/struct_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    assert any(item["op"] == "DECLARE_STRUCT" for item in data["ir"])
def test_duplicate_field_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad_struct.panther"
    src.write_text("struct User {\n    name\n    name\n}\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
