#!/usr/bin/env python3
from __future__ import annotations
import subprocess
from pathlib import Path

def run_artifact(path: str) -> tuple[int, str, str]:
    p = Path(path)
    if not p.exists():
        return 2, "", f"Artifact not found: {path}"
    proc = subprocess.run([str(p)], text=True, capture_output=True)
    return proc.returncode, proc.stdout, proc.stderr
