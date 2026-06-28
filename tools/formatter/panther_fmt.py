#!/usr/bin/env python3
from pathlib import Path
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("source")
parser.add_argument("--write", action="store_true")
args = parser.parse_args()

src = Path(args.source)
text = src.read_text(encoding="utf-8")

formatted = "\n".join(line.rstrip() for line in text.splitlines()) + "\n"

if args.write:
    src.write_text(formatted, encoding="utf-8")
    print(f"formatted:{src}")
else:
    print(formatted, end="")
