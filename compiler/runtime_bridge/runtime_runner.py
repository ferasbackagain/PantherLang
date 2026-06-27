#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
from pathlib import Path


class PantherRuntimeError(Exception):
    pass


def run_artifact(path: str | Path) -> dict:
    artifact = Path(path)
    if not artifact.exists():
        raise PantherRuntimeError(f"Artifact not found: {artifact}")
    if not artifact.is_file():
        raise PantherRuntimeError(f"Artifact is not a file: {artifact}")

    proc = subprocess.run([str(artifact)], text=True, capture_output=True)

    return {
        "ok": proc.returncode == 0,
        "returncode": proc.returncode,
        "stdout": proc.stdout,
        "stderr": proc.stderr,
        "artifact": str(artifact),
        "external_api_used": False,
        "network_used": False,
        "deterministic": True
    }


def print_json(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False))


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact")
    args = parser.parse_args()
    try:
        print_json(run_artifact(args.artifact))
    except PantherRuntimeError as exc:
        print_json({"ok": False, "error": str(exc), "external_api_used": False, "network_used": False, "deterministic": True})
        raise SystemExit(2)
