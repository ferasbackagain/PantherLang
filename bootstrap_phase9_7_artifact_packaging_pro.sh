#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo " PantherLang Phase 9.7 PRO - Artifact Packaging"
echo "============================================================"

mkdir -p toolchain/packager examples/phase9_packaging scripts docs/phase9 tests/phase9_7 dist

cat > toolchain/packager/artifact_packager.py <<'PY'
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
PY
chmod +x toolchain/packager/artifact_packager.py

cat > examples/phase9_packaging/packaging_demo.panther <<'EOF'
print "Phase 9.7 Artifact Packaging"
EOF

cat > docs/phase9/PHASE_9_7_STATUS.md <<'EOF'
# Phase 9.7 — Artifact Packaging

Completed:
- Artifact packager
- Package manifest
- SHA256 checksum
- tar.gz package generation
- package inspection
- Panther CLI package-artifact bridge
- release build packaging verification

Next: Phase 9.8 Cross-Platform Toolchain.
EOF

# Patch Panther CLI with pack command.
if ! grep -q 'toolchain/packager/artifact_packager.py' panther; then
python3 - <<'PY'
from pathlib import Path
p = Path("panther")
txt = p.read_text()
needle = '  cache)\n'
insert = '  pack)\n    shift\n    python3 "$ROOT/toolchain/packager/artifact_packager.py" "$@"\n    ;;\n\n'
if needle not in txt:
    needle = 'case "${1:-}" in\n'
if insert not in txt:
    txt = txt.replace(needle, insert + needle)
p.write_text(txt)
PY
chmod +x panther
fi

cat > scripts/verify_phase9_7_artifact_packaging.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 9.7 Artifact Packaging Verification"
echo "============================================================"

test -f toolchain/packager/artifact_packager.py
test -f examples/phase9_packaging/packaging_demo.panther
test -f docs/phase9/PHASE_9_7_STATUS.md
echo "✅ structure tests passed"

python3 -m py_compile toolchain/packager/artifact_packager.py
echo "✅ python compile passed"

./panther build examples/phase9_packaging/packaging_demo.panther --release >/tmp/p97_build.json
grep -q '"ok": true' /tmp/p97_build.json
test -f build/release/packaging_demo.sh
echo "✅ release build passed"

rm -rf /tmp/p97_dist
mkdir -p /tmp/p97_dist

./panther pack pack build/release/packaging_demo.sh --name packaging-demo --version 0.9.7 --out-dir /tmp/p97_dist >/tmp/p97_pack.json
grep -q '"ok": true' /tmp/p97_pack.json
grep -q '"phase": "9.7"' /tmp/p97_pack.json
test -f /tmp/p97_dist/packaging-demo-0.9.7.tar.gz
test -f /tmp/p97_dist/package.manifest.json
echo "✅ artifact packaging tests passed"

./panther pack inspect /tmp/p97_dist/packaging-demo-0.9.7.tar.gz >/tmp/p97_inspect.json
grep -q '"ok": true' /tmp/p97_inspect.json
grep -q '"has_manifest": true' /tmp/p97_inspect.json
grep -q 'packaging_demo.sh' /tmp/p97_inspect.json
echo "✅ package inspection tests passed"

tar -tzf /tmp/p97_dist/packaging-demo-0.9.7.tar.gz | grep -q 'package.manifest.json'
tar -tzf /tmp/p97_dist/packaging-demo-0.9.7.tar.gz | grep -q 'packaging_demo.sh'
echo "✅ tar package content tests passed"

echo "✅ PantherLang Phase 9.7 Artifact Packaging verification complete."
EOF
chmod +x scripts/verify_phase9_7_artifact_packaging.sh

echo "[phase9.7] Running verification..."
bash scripts/verify_phase9_7_artifact_packaging.sh

echo "============================================================"
echo " Phase 9.7 COMPLETE"
echo " Next: Phase 9.8 Cross-Platform Toolchain"
echo "============================================================"
