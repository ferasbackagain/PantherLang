#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import tarfile
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Any


class PantherPackagerError(Exception):
    pass


@dataclass
class PackageManifest:
    name: str
    version: str
    artifact: str
    checksum: str
    format: str = "tar.gz"
    phase: str = "9.7"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def package_artifact(artifact: Path, name: str, version: str = "0.1.0", out_dir: Path | None = None) -> dict[str, Any]:
    artifact = artifact.expanduser().resolve()
    if not artifact.exists():
        raise PantherPackagerError(f"Artifact not found: {artifact}")

    out_dir = (out_dir or Path.cwd() / "dist").resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    checksum = sha256(artifact)
    manifest = PackageManifest(
        name=name,
        version=version,
        artifact=artifact.name,
        checksum=checksum,
    )

    manifest_path = out_dir / "package.manifest.json"
    manifest_path.write_text(json.dumps(asdict(manifest), indent=2, sort_keys=True), encoding="utf-8")

    package_path = out_dir / f"{name}-{version}.tar.gz"
    with tarfile.open(package_path, "w:gz") as tar:
        tar.add(artifact, arcname=artifact.name)
        tar.add(manifest_path, arcname="package.manifest.json")

    return {
        "ok": True,
        "phase": "9.7",
        "name": name,
        "version": version,
        "artifact": str(artifact),
        "package": str(package_path),
        "manifest": str(manifest_path),
        "checksum": checksum,
    }


def inspect_package(package_path: Path) -> dict[str, Any]:
    package_path = package_path.expanduser().resolve()
    if not package_path.exists():
        raise PantherPackagerError(f"Package not found: {package_path}")

    with tarfile.open(package_path, "r:gz") as tar:
        names = tar.getnames()

    return {
        "ok": True,
        "phase": "9.7",
        "package": str(package_path),
        "files": names,
        "has_manifest": "package.manifest.json" in names,
    }


def main() -> int:
    parser = argparse.ArgumentParser(prog="panther-packager")
    sub = parser.add_subparsers(dest="cmd", required=True)

    pack = sub.add_parser("pack")
    pack.add_argument("artifact")
    pack.add_argument("--name", required=True)
    pack.add_argument("--version", default="0.1.0")
    pack.add_argument("--out-dir", default=None)

    inspect = sub.add_parser("inspect")
    inspect.add_argument("package")

    args = parser.parse_args()

    try:
        if args.cmd == "pack":
            result = package_artifact(
                Path(args.artifact),
                name=args.name,
                version=args.version,
                out_dir=Path(args.out_dir) if args.out_dir else None,
            )
            print(json.dumps(result, indent=2, sort_keys=True))
            return 0

        if args.cmd == "inspect":
            print(json.dumps(inspect_package(Path(args.package)), indent=2, sort_keys=True))
            return 0

    except PantherPackagerError as exc:
        print(json.dumps({"ok": False, "phase": "9.7", "error": str(exc)}, indent=2))
        return 2

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
