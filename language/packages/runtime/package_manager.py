#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any


class PantherPackageError(Exception):
    pass


@dataclass
class PackageManifest:
    name: str
    version: str
    kind: str
    entry: str
    dependencies: list[str]
    integrity: str
    signature: str
    sandbox_policy: str


class LocalPackageManager:
    VALID_KINDS = {"library", "agent", "plugin", "workflow", "tool"}
    BLOCKED_NAMES = {"malware", "stealer", "reverse-shell"}

    def __init__(self, registry: Path) -> None:
        self.registry = registry
        self.registry.mkdir(parents=True, exist_ok=True)

    def package_dir(self, name: str, version: str) -> Path:
        return self.registry / name / version

    def hash_content(self, content: str) -> str:
        return "sha256:" + hashlib.sha256(content.encode("utf-8")).hexdigest()

    def sign(self, name: str, version: str, integrity: str) -> str:
        payload = f"panther-signature::{name}::{version}::{integrity}"
        return "sig:" + hashlib.sha256(payload.encode("utf-8")).hexdigest()

    def validate_manifest(self, manifest: PackageManifest, content: str) -> None:
        if not manifest.name.strip():
            raise PantherPackageError("Package name cannot be empty")
        if manifest.name in self.BLOCKED_NAMES:
            raise PantherPackageError(f"Blocked package name: {manifest.name}")
        if manifest.kind not in self.VALID_KINDS:
            raise PantherPackageError(f"Invalid package kind: {manifest.kind}")
        expected_integrity = self.hash_content(content)
        if manifest.integrity != expected_integrity:
            raise PantherPackageError("Package integrity mismatch")
        expected_signature = self.sign(manifest.name, manifest.version, manifest.integrity)
        if manifest.signature != expected_signature:
            raise PantherPackageError("Package signature verification failed")
        if not manifest.sandbox_policy:
            raise PantherPackageError("Package sandbox policy is required")

    def create_manifest(self, name: str, version: str, kind: str, entry: str, content: str, dependencies: list[str]) -> PackageManifest:
        if kind not in self.VALID_KINDS:
            raise PantherPackageError(f"Invalid package kind: {kind}")
        integrity = self.hash_content(content)
        signature = self.sign(name, version, integrity)
        return PackageManifest(
            name=name,
            version=version,
            kind=kind,
            entry=entry,
            dependencies=dependencies,
            integrity=integrity,
            signature=signature,
            sandbox_policy="default_secure_ai_sandbox"
        )

    def publish(self, name: str, version: str, kind: str, entry: str, content: str, dependencies: list[str]) -> dict[str, Any]:
        manifest = self.create_manifest(name, version, kind, entry, content, dependencies)
        self.validate_manifest(manifest, content)
        target = self.package_dir(name, version)
        target.mkdir(parents=True, exist_ok=True)
        (target / "package.panther").write_text(content, encoding="utf-8")
        (target / "panther.package.json").write_text(json.dumps(asdict(manifest), indent=2), encoding="utf-8")
        return {
            "ok": True,
            "phase": "5.9",
            "action": "publish",
            "name": name,
            "version": version,
            "integrity": manifest.integrity,
            "signature_verified": True,
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
        }

    def install(self, name: str, version: str, dest: Path) -> dict[str, Any]:
        source = self.package_dir(name, version)
        if not source.exists():
            raise PantherPackageError(f"Package not found: {name}@{version}")
        manifest_path = source / "panther.package.json"
        content_path = source / "package.panther"
        manifest = PackageManifest(**json.loads(manifest_path.read_text(encoding="utf-8")))
        content = content_path.read_text(encoding="utf-8")
        self.validate_manifest(manifest, content)
        dest.mkdir(parents=True, exist_ok=True)
        install_dir = dest / name
        if install_dir.exists():
            shutil.rmtree(install_dir)
        shutil.copytree(source, install_dir)
        return {
            "ok": True,
            "phase": "5.9",
            "action": "install",
            "name": name,
            "version": version,
            "installed_to": str(install_dir),
            "integrity_verified": True,
            "signature_verified": True,
            "sandbox_policy_attached": True,
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
        }

    def demo(self) -> dict[str, Any]:
        content = 'agent helper role assistant permissions ["message"]\nprint "Panther package installed"\n'
        publish = self.publish("panther-ai-helper", "0.1.0", "agent", "package.panther", content, [])
        install = self.install("panther-ai-helper", "0.1.0", Path("/tmp/panther_phase5_9_installed"))
        return {
            "phase": "5.9",
            "demo": "ai-package-ecosystem",
            "ok": True,
            "published": publish["ok"],
            "installed": install["ok"],
            "integrity_verified": install["integrity_verified"],
            "signature_verified": install["signature_verified"],
            "sandbox_policy_attached": install["sandbox_policy_attached"],
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
        }


def print_json(data: Any) -> None:
    print(json.dumps(data, ensure_ascii=False))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-package-manager")
    parser.add_argument("--registry", default="/tmp/panther_phase5_9_registry")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("demo")

    neg = sub.add_parser("negative")
    neg.add_argument("--case", choices=["missing", "bad-kind", "blocked", "tamper"], required=True)

    args = parser.parse_args(argv)
    pm = LocalPackageManager(Path(args.registry))

    try:
        if args.cmd == "demo":
            print_json(pm.demo())
            return 0

        if args.cmd == "negative":
            if args.case == "missing":
                pm.install("missing-package", "0.0.1", Path("/tmp/panther_missing_install"))
            elif args.case == "bad-kind":
                pm.publish("bad-kind-package", "0.1.0", "illegal", "package.panther", "print 1\n", [])
            elif args.case == "blocked":
                pm.publish("malware", "0.1.0", "tool", "package.panther", "print 1\n", [])
            elif args.case == "tamper":
                content = "print 1\n"
                result = pm.publish("tamper-test", "0.1.0", "library", "package.panther", content, [])
                pkg = pm.package_dir("tamper-test", "0.1.0") / "package.panther"
                pkg.write_text("print 999\n", encoding="utf-8")
                pm.install("tamper-test", "0.1.0", Path("/tmp/panther_tamper_install"))

    except PantherPackageError as exc:
        print_json({
            "ok": False,
            "phase": "5.9",
            "error": str(exc),
            "external_api_used": False,
            "network_used": False,
            "deterministic": True,
        })
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
