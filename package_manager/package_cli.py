#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path


class PantherPackageError(Exception):
    pass


class PackageManager:
    def __init__(self, root: Path | None = None):
        self.root = root or Path.cwd()
        self.registry = self.root / "package_manager" / "local_registry"
        self.registry.mkdir(parents=True, exist_ok=True)

    def init_project(self, name: str, version: str = "0.1.0") -> Path:
        if not name.strip():
            raise PantherPackageError("Package name cannot be empty")
        manifest = self.root / "panther.toml"
        manifest.write_text(
            f'[project]\nname = "{name}"\nversion = "{version}"\n\n[dependencies]\n',
            encoding="utf-8",
        )
        return manifest

    def add(self, name: str, version: str = "latest") -> Path:
        if not name.strip():
            raise PantherPackageError("Dependency name cannot be empty")
        lock = self.root / "panther.lock"
        data = {"dependencies": {}}
        if lock.exists():
            data = json.loads(lock.read_text(encoding="utf-8"))
        data.setdefault("dependencies", {})[name] = version
        lock.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
        return lock

    def remove(self, name: str) -> Path:
        lock = self.root / "panther.lock"
        if not lock.exists():
            raise PantherPackageError("panther.lock not found")
        data = json.loads(lock.read_text(encoding="utf-8"))
        data.setdefault("dependencies", {}).pop(name, None)
        lock.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")
        return lock

    def list_packages(self) -> dict:
        lock = self.root / "panther.lock"
        if not lock.exists():
            return {"dependencies": {}}
        return json.loads(lock.read_text(encoding="utf-8"))


def main() -> int:
    parser = argparse.ArgumentParser(prog="Panther package")
    sub = parser.add_subparsers(dest="cmd", required=True)

    init_p = sub.add_parser("init")
    init_p.add_argument("name")

    add_p = sub.add_parser("add")
    add_p.add_argument("name")
    add_p.add_argument("--version", default="latest")

    remove_p = sub.add_parser("remove")
    remove_p.add_argument("name")

    sub.add_parser("list")

    args = parser.parse_args()
    pm = PackageManager(Path.cwd())

    try:
        if args.cmd == "init":
            path = pm.init_project(args.name)
            print(f"✅ package initialized: {path}")
            return 0
        if args.cmd == "add":
            path = pm.add(args.name, args.version)
            print(f"✅ dependency added: {args.name}@{args.version}")
            print(path)
            return 0
        if args.cmd == "remove":
            path = pm.remove(args.name)
            print(f"✅ dependency removed: {args.name}")
            print(path)
            return 0
        if args.cmd == "list":
            print(json.dumps(pm.list_packages(), indent=2, sort_keys=True))
            return 0
    except PantherPackageError as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, indent=2))
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
