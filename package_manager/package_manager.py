#!/usr/bin/env python3
from __future__ import annotations

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
