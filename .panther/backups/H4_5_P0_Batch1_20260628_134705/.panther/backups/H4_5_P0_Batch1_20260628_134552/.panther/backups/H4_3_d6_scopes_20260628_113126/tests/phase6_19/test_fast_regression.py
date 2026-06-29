from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_optimizer_fingerprint_is_stable() -> None:
    from compiler.optimization.optimizer import stable_fingerprint
    a = stable_fingerprint('print "hello"', {"mode": "fast"})
    b = stable_fingerprint('print "hello"', {"mode": "fast"})
    c = stable_fingerprint('print "bye"', {"mode": "fast"})
    assert a == b
    assert a != c


def test_fast_regression_demo_compile(tmp_path: Path) -> None:
    out = tmp_path / "fast.sh"
    proc = subprocess.run(
        [str(ROOT / "panther"), "compile", "examples/phase6_fast_regression/fast_regression_demo.panther", "--out", str(out)],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    run = subprocess.run([str(out)], text=True, capture_output=True)
    assert run.returncode == 0
    assert "Fast regression demo" in run.stdout


def test_regression_runner_help() -> None:
    proc = subprocess.run(
        [sys.executable, "tools/panther-regression/panther_regression.py", "--help"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    assert "--mode" in proc.stdout
