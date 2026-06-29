#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import tempfile
import time
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "bench.panther"
        src.write_text('print "Panther benchmark"\n', encoding="utf-8")
        start = time.perf_counter()
        proc = subprocess.run(
            [str(ROOT / "panther"), "build", str(src), "--release"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
        elapsed = time.perf_counter() - start

    report = {
        "ok": proc.returncode == 0,
        "stage": "H1",
        "suite": "benchmark",
        "build_seconds": round(elapsed, 6),
        "returncode": proc.returncode,
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if proc.returncode == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
