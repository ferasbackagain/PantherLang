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
        [str(ROOT / "panther"), "check", "examples/phase7_cli/check_demo.pan"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 0
    assert "check passed" in proc.stdout


def _panther_check(file: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(ROOT / "panther"), "check", file],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )


def test_check_clean_file() -> None:
    proc = _panther_check("tests/fixtures/security_clean.pan")
    assert proc.returncode == 0
    assert "check passed" in proc.stdout


def test_check_detects_hardcoded_secret_s001() -> None:
    proc = _panther_check("tests/fixtures/security_s001_only.pan")
    assert proc.returncode == 1
    assert "[S001]" in proc.stderr
    assert "[S005]" not in proc.stderr


def test_check_detects_dangerous_function_s002() -> None:
    proc = _panther_check("tests/fixtures/security_dangerous_fn.pan")
    assert proc.returncode == 1
    assert "[S002]" in proc.stderr


def test_check_detects_dangerous_call_s003() -> None:
    proc = _panther_check("tests/fixtures/security_dangerous_fn.pan")
    assert proc.returncode == 1
    assert "[S003]" in proc.stderr


def test_check_detects_shell_injection_s004() -> None:
    proc = _panther_check("tests/fixtures/security_injection.pan")
    assert proc.returncode == 1
    assert "[S004]" in proc.stderr


def test_check_detects_secret_pattern_s005() -> None:
    proc = _panther_check("tests/fixtures/security_s005_only.pan")
    assert proc.returncode == 1
    assert "[S005]" in proc.stderr
    assert "[S001]" not in proc.stderr


def test_panther_run_missing_fails() -> None:
    proc = subprocess.run(
        [str(ROOT / "panther"), "run", "missing.panther"],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 2
    assert "Source file not found" in proc.stdout
