from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "nlp" / "runtime" / "intent_compiler.py"


def run_cmd(*args: str):
    proc = subprocess.run(
        [sys.executable, str(RUNTIME), *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    return proc.returncode, json.loads(proc.stdout)


def test_compile_function_intent() -> None:
    code, data = run_cmd("compile", "--text", "Create a function that adds two numbers and print the result.")
    assert code == 0
    assert data["ok"] is True
    assert data["intent_kind"] == "function"
    assert data["external_api_used"] is False
    assert data["deterministic"] is True
    assert "fn add" in data["generated_source"]


def test_compile_print_intent() -> None:
    code, data = run_cmd("compile", "--text", 'Print "PantherLang is alive"')
    assert code == 0
    assert data["intent_kind"] == "print"
    assert 'print "PantherLang is alive"' in data["generated_source"]


def test_ambiguous_intent_fails() -> None:
    code, data = run_cmd("negative", "--case", "ambiguous")
    assert code == 2
    assert data["ok"] is False
    assert "Ambiguous intent" in data["error"]


def test_unsafe_intent_fails() -> None:
    code, data = run_cmd("negative", "--case", "unsafe")
    assert code == 2
    assert data["ok"] is False
    assert "Unsafe intent blocked" in data["error"]
