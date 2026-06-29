from __future__ import annotations
import json, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"
def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(COMPILER), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)
def test_module_demo(tmp_path: Path) -> None:
    out = tmp_path / "module.sh"
    code, data = run_cmd("compile", "examples/phase6_modules/module_demo.panther", "--out", str(out))
    assert code == 0 and data["ok"] is True
    assert any(item["op"] == "DECLARE_MODULE" for item in data["ir"])
    assert any(item["op"] == "IMPORT_MODULE" for item in data["ir"])
    proc = subprocess.run([str(out)], text=True, capture_output=True)
    assert proc.returncode == 0
    assert "Phase 6.16 modules" in proc.stdout
def test_invalid_module_fails(tmp_path: Path) -> None:
    src = tmp_path / "bad_module.panther"
    src.write_text("module 123.bad\n")
    code, data = run_cmd("compile", str(src), "--out", str(tmp_path / "bad.sh"))
    assert code == 2
    assert data["ok"] is False
