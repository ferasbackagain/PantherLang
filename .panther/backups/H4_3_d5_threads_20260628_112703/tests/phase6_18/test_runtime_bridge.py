from __future__ import annotations
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PANTHER = ROOT / "panther"
SRC = "examples/phase6_runtime/runtime_demo.panther"


def test_panther_build_and_run(tmp_path: Path) -> None:
    out = tmp_path / "runtime.sh"
    build = subprocess.run([str(PANTHER), "build", SRC, "--out", str(out)], cwd=ROOT, text=True, capture_output=True)
    assert build.returncode == 0
    assert '"ok": true' in build.stdout
    assert out.exists()

    run = subprocess.run([str(PANTHER), "run", SRC], cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0
    data = json.loads(run.stdout)
    assert data["ok"] is True
    assert "Runtime Bridge test" in data["stdout"]
    assert "42" in data["stdout"]


def test_panther_test_command() -> None:
    proc = subprocess.run([str(PANTHER), "test", SRC], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 0
    assert "Panther test passed" in proc.stdout


def test_runtime_missing_artifact_fails() -> None:
    proc = subprocess.run(["python3", "compiler/runtime_bridge/runtime_runner.py", "/tmp/no_such_panther_artifact.sh"], cwd=ROOT, text=True, capture_output=True)
    assert proc.returncode == 2
    data = json.loads(proc.stdout)
    assert data["ok"] is False
