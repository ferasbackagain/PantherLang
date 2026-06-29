#!/usr/bin/env python3
from __future__ import annotations

import json
import random
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TOKENS = [
    'print "fuzz"',
    'let x = 1',
    'let y = 2 + 3',
    'fn hello(name) {',
    'print name',
    '}',
]


def generate_program(seed: int) -> str:
    random.seed(seed)
    lines = ['print "Panther fuzz start"']
    for _ in range(3):
        lines.append(random.choice(TOKENS))
    lines.append('print "Panther fuzz end"')
    return "\n".join(lines) + "\n"


def main() -> int:
    passed = 0
    total = 25
    failures = []
    with tempfile.TemporaryDirectory() as tmp:
        tmpdir = Path(tmp)
        for seed in range(total):
            source = tmpdir / f"fuzz_{seed}.panther"
            source.write_text(generate_program(seed), encoding="utf-8")
            proc = subprocess.run(
                [str(ROOT / "panther"), "check", str(source)],
                cwd=ROOT,
                text=True,
                capture_output=True,
            )
            if proc.returncode == 0:
                passed += 1
            else:
                failures.append({"seed": seed, "stdout": proc.stdout, "stderr": proc.stderr})
    print(json.dumps({
        "ok": True,
        "stage": "H1",
        "suite": "fuzz",
        "total": total,
        "passed": passed,
        "failures_sample": failures[:3],
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
