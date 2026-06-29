from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_panther_run() -> None:
    proc = subprocess.run(
        [str(ROOT / "panther"), "run", "examples/phase7_cli/cli_run_demo.panther"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    assert "Panther CLI run works" in proc.stdout
    assert "Phase 7.2 CLI run foundation" in proc.stdout


def test_panther_check() -> None:
    proc = subprocess.run(
        [str(ROOT / "panther"), "check", "examples/phase7_cli/cli_run_demo.panther"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    assert "check passed" in proc.stdout


def test_panther_run_missing_fails() -> None:
    proc = subprocess.run(
        [str(ROOT / "panther"), "run", "missing.panther"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 2
    assert "Source file not found" in proc.stdout
