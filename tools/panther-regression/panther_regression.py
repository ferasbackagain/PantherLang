#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


FAST_CHECKS = [
    "scripts/verify_phase6_12_control_flow.sh",
    "scripts/verify_phase6_13_loops.sh",
    "scripts/verify_phase6_14_functions.sh",
    "scripts/verify_phase6_15_structs.sh",
    "scripts/verify_phase6_16_modules.sh",
    "scripts/verify_phase6_18_runtime_bridge.sh",
]


def run_check(script: str, timeout: int) -> dict:
    start = time.time()
    proc = subprocess.run(
        ["bash", script],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        timeout=timeout,
    )
    return {
        "script": script,
        "ok": proc.returncode == 0,
        "returncode": proc.returncode,
        "seconds": round(time.time() - start, 3),
        "tail": "\n".join(proc.stdout.splitlines()[-8:]),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["fast", "full"], default="fast")
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()

    checks = FAST_CHECKS
    results = []
    ok = True

    for script in checks:
        if not (ROOT / script).exists():
            results.append({"script": script, "ok": False, "error": "missing"})
            ok = False
            continue
        try:
            result = run_check(script, args.timeout)
        except subprocess.TimeoutExpired:
            result = {"script": script, "ok": False, "error": "timeout", "seconds": args.timeout}
        results.append(result)
        ok = ok and bool(result.get("ok"))

    report = {
        "ok": ok,
        "mode": args.mode,
        "phase": "6.19",
        "checks": results,
        "deterministic": True,
    }
    print(json.dumps(report, indent=2))
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
