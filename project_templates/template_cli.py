#!/usr/bin/env python3
from pathlib import Path
import shutil
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("kind", choices=["console", "web", "api"])
parser.add_argument("name")
args = parser.parse_args()

root = Path(__file__).resolve().parents[1]
src = root / "templates" / args.kind
dst = Path.cwd() / args.name

if dst.exists():
    raise SystemExit(f"Project already exists: {dst}")

(dst / "src").mkdir(parents=True, exist_ok=True)
(dst / "tests").mkdir(exist_ok=True)
(dst / "docs").mkdir(exist_ok=True)
(dst / "build").mkdir(exist_ok=True)

source_template = src / "main.panther"
if source_template.exists():
    shutil.copy(source_template, dst / "src" / "main.panther")
else:
    (dst / "src" / "main.panther").write_text(
        f'module {args.name}.main\n\nprint "Hello from {args.name}"\n',
        encoding="utf-8",
    )

(dst / "panther.toml").write_text(
    f'[project]\nname = "{args.name}"\ntemplate = "{args.kind}"\nentry = "src/main.panther"\n',
    encoding="utf-8",
)

print(f"Created {dst}")
