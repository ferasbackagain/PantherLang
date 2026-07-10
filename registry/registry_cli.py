#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
from dataclasses import dataclass, asdict
from pathlib import Path


class RegistryError(Exception):
    pass


@dataclass
class RegistryPackage:
    name: str
    version: str
    source: str
    description: str = ""


class PantherRegistry:
    def __init__(self, root: Path | None = None):
        self.project_root = Path(__file__).resolve().parents[1]
        self.root = root or (self.project_root / "registry")
        self.packages_dir = self.root / "packages"
        self.published_dir = self.root / "published"
        self.index_path = self.root / "index.json"
        self.packages_dir.mkdir(parents=True, exist_ok=True)
        self.published_dir.mkdir(parents=True, exist_ok=True)

    def init(self) -> dict:
        if not self.index_path.exists():
            self.index_path.write_text(json.dumps({"packages": {}}, indent=2, sort_keys=True), encoding="utf-8")
        return {"ok": True, "phase": "10.3", "registry": str(self.root), "index": str(self.index_path)}

    def _load(self) -> dict:
        self.init()
        return json.loads(self.index_path.read_text(encoding="utf-8"))

    def _save(self, data: dict) -> None:
        self.index_path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")

    def publish(self, source: Path, name: str, version: str, description: str = "") -> dict:
        source = source.expanduser().resolve()
        if not source.exists():
            raise RegistryError(f"Package source not found: {source}")

        data = self._load()
        package_key = f"{name}@{version}"
        target_dir = self.published_dir / name / version
        target_dir.mkdir(parents=True, exist_ok=True)

        if source.is_dir():
            dst = target_dir / source.name
            if dst.exists():
                shutil.rmtree(dst)
            shutil.copytree(source, dst)
        else:
            shutil.copy2(source, target_dir / source.name)

        pkg = RegistryPackage(name=name, version=version, source=str(target_dir), description=description)
        data.setdefault("packages", {})[package_key] = asdict(pkg)
        self._save(data)

        return {"ok": True, "phase": "10.3", "published": package_key, "path": str(target_dir)}

    def search(self, query: str = "") -> dict:
        data = self._load()
        packages = data.get("packages", {})
        result = {
            key: value for key, value in packages.items()
            if not query or query.lower() in key.lower() or query.lower() in value.get("description", "").lower()
        }
        return {"ok": True, "phase": "10.3", "query": query, "results": result}

    def list(self) -> dict:
        return self.search("")

    def install(self, name: str, version: str, dest: Path | None = None) -> dict:
        data = self._load()
        key = f"{name}@{version}"
        if key not in data.get("packages", {}):
            raise RegistryError(f"Package not found: {key}")

        dest = (dest or Path.cwd() / "packages" / name).resolve()
        source = Path(data["packages"][key]["source"])
        dest.parent.mkdir(parents=True, exist_ok=True)

        if dest.exists():
            if dest.is_dir():
                shutil.rmtree(dest)
            else:
                dest.unlink()

        shutil.copytree(source, dest)
        return {"ok": True, "phase": "10.3", "installed": key, "destination": str(dest)}


def main() -> int:
    parser = argparse.ArgumentParser(prog="Panther registry")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("init")

    pub = sub.add_parser("publish")
    pub.add_argument("source")
    pub.add_argument("--name", required=True)
    pub.add_argument("--version", required=True)
    pub.add_argument("--description", default="")

    search = sub.add_parser("search")
    search.add_argument("query", nargs="?", default="")

    sub.add_parser("list")

    install = sub.add_parser("install")
    install.add_argument("name")
    install.add_argument("--version", required=True)
    install.add_argument("--dest", default=None)

    args = parser.parse_args()
    registry = PantherRegistry()

    try:
        if args.cmd == "init":
            result = registry.init()
        elif args.cmd == "publish":
            result = registry.publish(Path(args.source), args.name, args.version, args.description)
        elif args.cmd == "search":
            result = registry.search(args.query)
        elif args.cmd == "list":
            result = registry.list()
        elif args.cmd == "install":
            result = registry.install(args.name, args.version, Path(args.dest) if args.dest else None)
        else:
            return 1

        print(json.dumps(result, indent=2, sort_keys=True))
        return 0

    except RegistryError as exc:
        print(json.dumps({"ok": False, "phase": "10.3", "error": str(exc)}, indent=2, sort_keys=True))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
