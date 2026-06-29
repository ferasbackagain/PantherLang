from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "memory" / "runtime" / "memory_runtime.py"


def run_cmd(*args: str) -> tuple[int, dict | list]:
    proc = subprocess.run(
        [sys.executable, str(RUNTIME), *args],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    payload = json.loads(proc.stdout)
    return proc.returncode, payload


def test_memory_put_get_search_context(tmp_path: Path) -> None:
    store = tmp_path / "store.json"

    code, put = run_cmd("--store", str(store), "put", "--key", "alpha", "--scope", "project", "--value", "Panther context memory", "--trust", "verified", "--tags", "memory,context")
    assert code == 0
    assert put["key"] == "alpha"
    assert put["trust"] == "verified"

    code, got = run_cmd("--store", str(store), "get", "--key", "alpha", "--scope", "project")
    assert code == 0
    assert got[0]["value"] == "Panther context memory"

    code, hits = run_cmd("--store", str(store), "search", "--query", "context", "--scope", "project")
    assert code == 0
    assert hits[0]["key"] == "alpha"

    code, ctx = run_cmd("--store", str(store), "context", "--query", "context", "--scope", "project")
    assert code == 0
    assert ctx["phase"] == "5.3"
    assert ctx["external_api_used"] is False
    assert "Panther context memory" in ctx["assembled_context"]


def test_invalid_scope_fails(tmp_path: Path) -> None:
    store = tmp_path / "store.json"
    proc = subprocess.run(
        [
            sys.executable,
            str(RUNTIME),
            "--store",
            str(store),
            "put",
            "--key",
            "bad",
            "--scope",
            "illegal",
            "--value",
            "x",
        ],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    assert proc.returncode == 2
    payload = json.loads(proc.stdout)
    assert payload["ok"] is False
    assert "Invalid scope" in payload["error"]
