#!/usr/bin/env python3
from __future__ import annotations

import json
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    lines = ['print "Panther stress start"']
    for i in range(200):
        lines.append(f'print "line {i}"')
    lines.append('print "Panther stress end"')

    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "stress.panther"
        src.write_text("\n".join(lines) + "\n", encoding="utf-8")
        proc = subprocess.run(
            [str(ROOT / "panther"), "build", str(src), "--release"],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )

    report = {
        "ok": proc.returncode == 0,
        "stage": "H1",
        "suite": "stress",
        "lines": len(lines),
        "returncode": proc.returncode,
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if proc.returncode == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
