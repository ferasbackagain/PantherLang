#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
COMPILER = ROOT / "compiler" / "pipeline" / "panther_compiler.py"


class PantherCLIError(Exception):
    pass


def print_json(data: Any) -> None:
    print(json.dumps(data, indent=2, sort_keys=True))


def run_panther_file(source: Path) -> int:
    if not source.exists():
        raise PantherCLIError(f"Source file not found: {source}")
    if source.suffix != ".panther":
        raise PantherCLIError("panther run expects a .panther file")

    build_dir = ROOT / "build" / "panther-run"
    build_dir.mkdir(parents=True, exist_ok=True)
    artifact = build_dir / f"{source.stem}.sh"

    compile_proc = subprocess.run(
        [sys.executable, str(COMPILER), "compile", str(source), "--out", str(artifact)],
        cwd=ROOT,
        text=True,
        capture_output=True,
    )
    if compile_proc.returncode != 0:
        sys.stdout.write(compile_proc.stdout)
        sys.stderr.write(compile_proc.stderr)
        return compile_proc.returncode

    run_proc = subprocess.run([str(artifact)], cwd=ROOT, text=True)
    return run_proc.returncode


def build_panther_file(source: Path, out: Path | None = None) -> int:
    if not source.exists():
        raise PantherCLIError(f"Source file not found: {source}")
    if source.suffix != ".panther":
        raise PantherCLIError("panther build expects a .panther file")

    out = out or (ROOT / "build" / f"{source.stem}.sh")
    out.parent.mkdir(parents=True, exist_ok=True)

    proc = subprocess.run(
        [sys.executable, str(COMPILER), "compile", str(source), "--out", str(out)],
        cwd=ROOT,
        text=True,
    )
    if proc.returncode == 0:
        print(f"✅ build complete: {out}")
    return proc.returncode


def check_panther_file(source: Path) -> int:
    if not source.exists():
        raise PantherCLIError(f"Source file not found: {source}")
    with tempfile.NamedTemporaryFile(prefix="panther_check_", suffix=".sh") as tmp:
        proc = subprocess.run(
            [sys.executable, str(COMPILER), "compile", str(source), "--out", tmp.name],
            cwd=ROOT,
            text=True,
            capture_output=True,
        )
    if proc.returncode == 0:
        print("✅ check passed")
    else:
        sys.stdout.write(proc.stdout)
        sys.stderr.write(proc.stderr)
    return proc.returncode


def new_project(name: str) -> int:
    if not name or "/" in name or "\\" in name:
        raise PantherCLIError("Invalid project name")
    project = Path.cwd() / name
    if project.exists():
        raise PantherCLIError(f"Project already exists: {project}")

    (project / "src").mkdir(parents=True)
    (project / "tests").mkdir()
    (project / "docs").mkdir()
    (project / "build").mkdir()

    (project / "panther.toml").write_text(
        f'[project]\nname = "{name}"\nversion = "0.1.0"\nphase = "7.2"\n',
        encoding="utf-8",
    )
    (project / "src" / "main.panther").write_text(
        f'module {name}.main\n\nprint "Hello from {name}"\n',
        encoding="utf-8",
    )
    print(f"✅ Panther project created: {project}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther")
    sub = parser.add_subparsers(dest="cmd", required=True)

    run_p = sub.add_parser("run")
    run_p.add_argument("source")

    build_p = sub.add_parser("build")
    build_p.add_argument("source")
    build_p.add_argument("--out", default=None)

    check_p = sub.add_parser("check")
    check_p.add_argument("source")

    new_p = sub.add_parser("new")
    new_p.add_argument("name")

    sub.add_parser("doctor")

    args = parser.parse_args(argv)

    try:
        if args.cmd == "run":
            return run_panther_file(Path(args.source))
        if args.cmd == "build":
            out = Path(args.out) if args.out else None
            return build_panther_file(Path(args.source), out)
        if args.cmd == "check":
            return check_panther_file(Path(args.source))
        if args.cmd == "new":
            return new_project(args.name)
        if args.cmd == "doctor":
            print("Panther CLI v2: OK")
            print("phase: 7.2")
            print("commands: new, run, build, check")
            return 0
    except PantherCLIError as exc:
        print_json({"ok": False, "phase": "7.2", "error": str(exc)})
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
