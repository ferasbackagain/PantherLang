#!/usr/bin/env bash
set -euo pipefail

# PantherLang Phase 5.9 Professional
# AI Package Ecosystem + Registry + Signing Simulation + Strong Practical Test Suite

PHASE="5.9"
PROJECT_ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$PROJECT_ROOT/.phase_backups/phase5_9_pro_$STAMP"

echo "============================================================"
echo " PantherLang Phase 5.9 PRO - AI Package Ecosystem"
echo "============================================================"
echo "[phase5.9] Project root: $PROJECT_ROOT"

fail(){ echo "[phase5.9][ERROR] $1" >&2; exit 1; }
require_file(){ [ -f "$1" ] || fail "Required file missing: $1"; }
require_dir(){ [ -d "$1" ] || fail "Required directory missing: $1"; }

require_file "README.md"
require_file "VERSION_PLAN.md"
require_file "CHANGELOG.md"
require_dir "language"
require_dir "scripts"
require_dir "architecture"

for s in \
 scripts/verify_phase5_1_ai_native_core.sh \
 scripts/verify_phase5_2_intelligent_type_system.sh \
 scripts/verify_phase5_3_memory_context_engine.sh \
 scripts/verify_phase5_4_multi_agent_runtime.sh \
 scripts/verify_phase5_5_natural_language_programming.sh \
 scripts/verify_phase5_6_ai_optimizing_compiler.sh \
 scripts/verify_phase5_7_distributed_execution.sh \
 scripts/verify_phase5_8_secure_ai_sandbox.sh
do
  require_file "$s"
done

echo "[phase5.9] Verifying Phase 5.1 -> 5.8 dependencies..."
for s in \
 scripts/verify_phase5_1_ai_native_core.sh \
 scripts/verify_phase5_2_intelligent_type_system.sh \
 scripts/verify_phase5_3_memory_context_engine.sh \
 scripts/verify_phase5_4_multi_agent_runtime.sh \
 scripts/verify_phase5_5_natural_language_programming.sh \
 scripts/verify_phase5_6_ai_optimizing_compiler.sh \
 scripts/verify_phase5_7_distributed_execution.sh \
 scripts/verify_phase5_8_secure_ai_sandbox.sh
do
  bash "$s" >/tmp/panther_phase5_9_dependency.log
done

mkdir -p "$BACKUP_DIR"
backup_if_exists(){ local t="$1"; if [ -e "$t" ]; then mkdir -p "$BACKUP_DIR/$(dirname "$t")"; cp -a "$t" "$BACKUP_DIR/$t"; fi; }

echo "[phase5.9] Creating backup at: $BACKUP_DIR"
for t in language/packages language/ai/packages architecture/AI_PACKAGE_ECOSYSTEM.md docs/phase5/PHASE_5_9_STATUS.md examples/packages tests/phase5_9 scripts/verify_phase5_9_ai_package_ecosystem.sh scripts/run_phase5_9_practical_demo.sh CHANGELOG.md; do
  backup_if_exists "$t"
done

echo "[phase5.9] Creating AI Package Ecosystem directories..."
mkdir -p language/packages/{core,runtime,schemas,policies,registry} language/ai/packages architecture docs/phase5 examples/packages tests/phase5_9 scripts

cat > architecture/AI_PACKAGE_ECOSYSTEM.md <<'MD'
# PantherLang Phase 5.9 — AI Package Ecosystem

Phase 5.9 introduces the first deterministic AI package ecosystem foundation.

## Mission

PantherLang needs a package ecosystem designed for AI-native programming from day one.

This phase creates:

- package manifest format
- local registry
- deterministic package publishing
- deterministic package installation
- package integrity hash
- signing simulation
- dependency validation
- sandbox/security policy integration
- practical package workflow demo
- negative tests

## Security Principle

No package is trusted without proof:
manifest + integrity + policy + deterministic install + audit record.

## Offline Guarantee

This phase uses a local registry only. It does not call external networks.
MD

cat > language/packages/core/package_manifest.json <<'JSON'
{
  "name": "PantherLang AI Package Ecosystem",
  "phase": "5.9",
  "version": "0.5.9-ai-package-ecosystem-pro",
  "status": "experimental-foundation",
  "depends_on": ["5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8"],
  "external_api_required": false,
  "network_required": false,
  "features": [
    "package_manifest",
    "local_registry",
    "deterministic_publish",
    "deterministic_install",
    "integrity_hash",
    "signature_simulation",
    "dependency_validation",
    "security_policy",
    "practical_demo",
    "negative_tests"
  ],
  "testing_standard": ["structure", "schema", "runtime", "integrity", "negative", "practical"]
}
JSON

cat > language/packages/core/package_types.panther <<'PAN'
# PantherLang Package Types
# Phase 5.9 syntax foundation

type PackageName = String
type PackageVersion = String
type PackageKind = "library" | "agent" | "plugin" | "workflow" | "tool"

type PantherPackage {
  name: PackageName
  version: PackageVersion
  kind: PackageKind
  entry: String
  dependencies: List<String>
  integrity: String
}

type PackageInstallResult {
  ok: Bool
  name: PackageName
  version: PackageVersion
  verified: Bool
}
PAN

cat > language/ai/packages/ai_package_types.panther <<'PAN'
# PantherLang AI Package Types
# Phase 5.9 AI-native package foundation

type AIAgentPackage = PantherPackage
type AIToolPackage = PantherPackage
type AIWorkflowPackage = PantherPackage

type PackageTrustReport {
  ok: Bool
  integrity_verified: Bool
  signature_verified: Bool
  sandbox_policy_attached: Bool
}
PAN

cat > language/packages/policies/default_package.policy.json <<'JSON'
{
  "name": "default_package",
  "phase": "5.9",
  "allow_network_registry": false,
  "allow_unsigned_packages": false,
  "require_integrity_hash": true,
  "require_sandbox_policy": true,
  "require_audit": true,
  "allowed_package_kinds": [
    "library",
    "agent",
    "plugin",
    "workflow",
    "tool"
  ],
  "blocked_names": [
    "malware",
    "stealer",
    "reverse-shell"
  ]
}
JSON

cat > language/packages/schemas/package.schema.json <<'JSON'
{
  "title": "PantherLang Package Manifest",
  "phase": "5.9",
  "type": "object",
  "required": ["name", "version", "kind", "entry", "dependencies", "integrity", "signature", "sandbox_policy"],
  "properties": {
    "name": { "type": "string" },
    "version": { "type": "string" },
    "kind": { "type": "string" },
    "entry": { "type": "string" },
    "dependencies": { "type": "array", "items": { "type": "string" } },
    "integrity": { "type": "string" },
    "signature": { "type": "string" },
    "sandbox_policy": { "type": "string" }
  }
}
JSON

cat > language/packages/runtime/package_manager.py <<'PY'
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
PY
chmod +x language/packages/runtime/package_manager.py

cat > examples/packages/phase5_9_package.panther <<'PAN'
# PantherLang Phase 5.9 AI Package Ecosystem practical example

package "panther-ai-helper" version "0.1.0" kind "agent" {
  entry "package.panther"
  sandbox_policy "default_secure_ai_sandbox"
}

publish package to local registry
install package from local registry

print "Panther package installed"
PAN

cat > examples/packages/phase5_9_practical_expected.txt <<'TXT'
demo=ai-package-ecosystem
ok=true
published=true
installed=true
integrity_verified=true
signature_verified=true
sandbox_policy_attached=true
external_api_used=false
network_used=false
deterministic=true
TXT

cat > scripts/run_phase5_9_practical_demo.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

REG="/tmp/panther_phase5_9_demo_registry_$$"
OUT="$(python3 language/packages/runtime/package_manager.py --registry "$REG" demo)"

python3 - "$OUT" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
assert data["phase"] == "5.9"
assert data["demo"] == "ai-package-ecosystem"
assert data["ok"] is True
assert data["published"] is True
assert data["installed"] is True
assert data["integrity_verified"] is True
assert data["signature_verified"] is True
assert data["sandbox_policy_attached"] is True
assert data["external_api_used"] is False
assert data["network_used"] is False
assert data["deterministic"] is True
print("demo=ai-package-ecosystem")
print("ok=true")
print("published=true")
print("installed=true")
print("integrity_verified=true")
print("signature_verified=true")
print("sandbox_policy_attached=true")
print("external_api_used=false")
print("network_used=false")
print("deterministic=true")
PY

rm -rf "$REG"
SH
chmod +x scripts/run_phase5_9_practical_demo.sh

cat > tests/phase5_9/test_package_manager.py <<'PY'
from __future__ import annotations
import json, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "language" / "packages" / "runtime" / "package_manager.py"

def run_cmd(*args: str):
    proc = subprocess.run([sys.executable, str(RUNTIME), *args], cwd=ROOT, text=True, capture_output=True)
    return proc.returncode, json.loads(proc.stdout)

def test_demo_package_manager() -> None:
    code, data = run_cmd("--registry", "/tmp/panther_phase5_9_pytest_registry", "demo")
    assert code == 0
    assert data["ok"] is True
    assert data["integrity_verified"] is True
    assert data["signature_verified"] is True
    assert data["network_used"] is False

def test_missing_package_fails() -> None:
    code, data = run_cmd("--registry", "/tmp/panther_phase5_9_missing_registry", "negative", "--case", "missing")
    assert code == 2
    assert "Package not found" in data["error"]

def test_bad_kind_fails() -> None:
    code, data = run_cmd("--registry", "/tmp/panther_phase5_9_bad_kind_registry", "negative", "--case", "bad-kind")
    assert code == 2
    assert "Invalid package kind" in data["error"]

def test_tamper_fails() -> None:
    code, data = run_cmd("--registry", "/tmp/panther_phase5_9_tamper_registry", "negative", "--case", "tamper")
    assert code == 2
    assert "integrity mismatch" in data["error"]
PY

cat > docs/phase5/PHASE_5_9_STATUS.md <<'MD'
# Phase 5.9 Status — AI Package Ecosystem PRO

## Completed

- AI Package Ecosystem architecture.
- Package manifest.
- Package and AI package type definitions.
- Default package policy.
- Package schema.
- Local package registry runtime.
- Deterministic publish/install.
- Integrity hash verification.
- Signature simulation.
- Sandbox policy attachment.
- Practical package workflow demo.
- Negative/failure tests.
- Pytest suite.
- Professional verification script.

## Next Phase

Phase 5.10 — Final Integration & Verification.
MD

cat > scripts/verify_phase5_9_ai_package_ecosystem.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "============================================================"
echo " PantherLang Phase 5.9 PRO Verification"
echo "============================================================"

for s in \
 scripts/verify_phase5_1_ai_native_core.sh \
 scripts/verify_phase5_2_intelligent_type_system.sh \
 scripts/verify_phase5_3_memory_context_engine.sh \
 scripts/verify_phase5_4_multi_agent_runtime.sh \
 scripts/verify_phase5_5_natural_language_programming.sh \
 scripts/verify_phase5_6_ai_optimizing_compiler.sh \
 scripts/verify_phase5_7_distributed_execution.sh \
 scripts/verify_phase5_8_secure_ai_sandbox.sh
do
  bash "$s" >/tmp/panther_phase5_9_dependency_verify.log
done

test -f architecture/AI_PACKAGE_ECOSYSTEM.md
test -f language/packages/core/package_manifest.json
test -f language/packages/core/package_types.panther
test -f language/ai/packages/ai_package_types.panther
test -f language/packages/policies/default_package.policy.json
test -f language/packages/schemas/package.schema.json
test -x language/packages/runtime/package_manager.py
test -f examples/packages/phase5_9_package.panther
test -f examples/packages/phase5_9_practical_expected.txt
test -x scripts/run_phase5_9_practical_demo.sh
test -f tests/phase5_9/test_package_manager.py
test -f docs/phase5/PHASE_5_9_STATUS.md
echo "✅ structure tests passed"

python3 - <<'PY'
import json
from pathlib import Path
m = json.loads(Path("language/packages/core/package_manifest.json").read_text())
assert m["phase"] == "5.9"
for dep in ["5.1","5.2","5.3","5.4","5.5","5.6","5.7","5.8"]:
    assert dep in m["depends_on"]
assert m["external_api_required"] is False
assert m["network_required"] is False
assert "local_registry" in m["features"]
assert "signature_simulation" in m["features"]
p = json.loads(Path("language/packages/policies/default_package.policy.json").read_text())
assert p["allow_network_registry"] is False
assert p["allow_unsigned_packages"] is False
assert p["require_integrity_hash"] is True
assert p["require_sandbox_policy"] is True
s = json.loads(Path("language/packages/schemas/package.schema.json").read_text())
for key in ["name","version","kind","entry","dependencies","integrity","signature","sandbox_policy"]:
    assert key in s["required"]
PY
echo "✅ schema tests passed"

REG="/tmp/panther_phase5_9_verify_registry_$$"
DEMO_JSON="$(python3 language/packages/runtime/package_manager.py --registry "$REG" demo)"
echo "$DEMO_JSON" | grep -q '"phase": "5.9"'
echo "$DEMO_JSON" | grep -q '"ok": true'
echo "$DEMO_JSON" | grep -q '"published": true'
echo "$DEMO_JSON" | grep -q '"installed": true'
echo "$DEMO_JSON" | grep -q '"integrity_verified": true'
echo "$DEMO_JSON" | grep -q '"signature_verified": true'
echo "$DEMO_JSON" | grep -q '"sandbox_policy_attached": true'
echo "$DEMO_JSON" | grep -q '"network_used": false'
echo "✅ package manager runtime tests passed"

set +e
BAD_MISSING="$(python3 language/packages/runtime/package_manager.py --registry /tmp/panther_phase5_9_missing_$$ negative --case missing)"
BAD_MISSING_CODE=$?
BAD_KIND="$(python3 language/packages/runtime/package_manager.py --registry /tmp/panther_phase5_9_badkind_$$ negative --case bad-kind)"
BAD_KIND_CODE=$?
BAD_BLOCK="$(python3 language/packages/runtime/package_manager.py --registry /tmp/panther_phase5_9_block_$$ negative --case blocked)"
BAD_BLOCK_CODE=$?
BAD_TAMPER="$(python3 language/packages/runtime/package_manager.py --registry /tmp/panther_phase5_9_tamper_$$ negative --case tamper)"
BAD_TAMPER_CODE=$?
set -e
if [ "$BAD_MISSING_CODE" -ne 2 ] || [ "$BAD_KIND_CODE" -ne 2 ] || [ "$BAD_BLOCK_CODE" -ne 2 ] || [ "$BAD_TAMPER_CODE" -ne 2 ]; then
  echo "[verify_phase5.9][ERROR] negative tests must fail with exit code 2"
  exit 1
fi
echo "$BAD_MISSING" | grep -q 'Package not found'
echo "$BAD_KIND" | grep -q 'Invalid package kind'
echo "$BAD_BLOCK" | grep -q 'Blocked package name'
echo "$BAD_TAMPER" | grep -q 'integrity mismatch'
echo "✅ negative/failure tests passed"

PRACTICAL_OUT="$(bash scripts/run_phase5_9_practical_demo.sh)"
echo "$PRACTICAL_OUT" | grep -q 'demo=ai-package-ecosystem'
echo "$PRACTICAL_OUT" | grep -q 'published=true'
echo "$PRACTICAL_OUT" | grep -q 'installed=true'
echo "$PRACTICAL_OUT" | grep -q 'integrity_verified=true'
echo "$PRACTICAL_OUT" | grep -q 'signature_verified=true'
echo "$PRACTICAL_OUT" | grep -q 'sandbox_policy_attached=true'
echo "✅ practical AI package ecosystem demo passed"

if command -v pytest >/dev/null 2>&1; then
  pytest -q tests/phase5_9 >/tmp/panther_phase5_9_pytest.log
  echo "✅ pytest suite passed"
else
  python3 -m py_compile language/packages/runtime/package_manager.py
  echo "✅ python compile test passed"
fi

rm -rf "$REG"
echo "✅ PantherLang Phase 5.9 AI Package Ecosystem verification complete."
SH
chmod +x scripts/verify_phase5_9_ai_package_ecosystem.sh

cat >> CHANGELOG.md <<'MD'

## Phase 5.9 — AI Package Ecosystem PRO

Added deterministic AI package ecosystem foundation:

- package manifest and type definitions
- AI package types
- package security policy
- package schema
- local registry runtime
- deterministic publish/install
- integrity hash verification
- signature simulation
- sandbox policy attachment
- practical package demo
- negative/failure tests
- pytest suite
- professional verification gates

Phase 5.9 depends on Phase 5.1 through Phase 5.8.
MD

echo "[phase5.9] Running professional verification..."
bash scripts/verify_phase5_9_ai_package_ecosystem.sh

echo "============================================================"
echo " Phase 5.9 COMPLETE"
echo " Next: Phase 5.10 Final Integration & Verification"
echo "============================================================"
