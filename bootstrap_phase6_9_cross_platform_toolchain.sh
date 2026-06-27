#!/usr/bin/env bash
set -euo pipefail

PHASE="6.9"
ROOT="$(pwd)"
REPORT_DIR="build/reports"
VERIFY="verify_phase6_9_cross_platform_toolchain.sh"

echo "[PantherLang 6.9] Starting Phase 6.9 bootstrap: Cross Platform Toolchain"

mkdir -p tools/panther-toolchain/panther_toolchain \
         tools/panther-toolchain/tests \
         tools/panther-toolchain/config \
         examples/phase_6_9_toolchain \
         docs/phase_6 \
         scripts \
         "$REPORT_DIR"

cat > tools/panther-toolchain/panther_toolchain/__init__.py <<'PY'
"""PantherLang cross-platform toolchain support."""
from .targets import TargetTriple, TARGETS, parse_target
from .resolver import ToolchainResolver
from .builder import CrossPlatformBuilder
PY

cat > tools/panther-toolchain/panther_toolchain/targets.py <<'PY'
from dataclasses import dataclass

@dataclass(frozen=True)
class TargetTriple:
    arch: str
    vendor: str
    os: str
    abi: str = "gnu"

    @property
    def triple(self) -> str:
        return f"{self.arch}-{self.vendor}-{self.os}-{self.abi}"

    @property
    def executable_suffix(self) -> str:
        return ".exe" if self.os == "windows" else ""

    @property
    def object_suffix(self) -> str:
        return ".obj" if self.os == "windows" else ".o"

    @property
    def library_prefix(self) -> str:
        return "" if self.os == "windows" else "lib"

    @property
    def shared_library_suffix(self) -> str:
        return {"linux": ".so", "darwin": ".dylib", "windows": ".dll"}.get(self.os, ".so")

TARGETS = {
    "linux-x86_64": TargetTriple("x86_64", "unknown", "linux", "gnu"),
    "linux-aarch64": TargetTriple("aarch64", "unknown", "linux", "gnu"),
    "macos-x86_64": TargetTriple("x86_64", "apple", "darwin", "none"),
    "macos-aarch64": TargetTriple("aarch64", "apple", "darwin", "none"),
    "windows-x86_64": TargetTriple("x86_64", "pc", "windows", "msvc"),
}

def parse_target(name: str) -> TargetTriple:
    if name in TARGETS:
        return TARGETS[name]
    for target in TARGETS.values():
        if name == target.triple:
            return target
    raise ValueError(f"Unsupported target: {name}")
PY

cat > tools/panther-toolchain/panther_toolchain/resolver.py <<'PY'
from dataclasses import dataclass
from .targets import TargetTriple, parse_target

@dataclass(frozen=True)
class ToolchainPlan:
    target: TargetTriple
    linker: str
    archiver: str
    runner: str
    sysroot_required: bool

class ToolchainResolver:
    def resolve(self, target_name: str) -> ToolchainPlan:
        target = parse_target(target_name)
        if target.os == "windows":
            return ToolchainPlan(target, "lld-link", "llvm-lib", "wine", True)
        if target.os == "darwin":
            return ToolchainPlan(target, "ld64.lld", "llvm-ar", "native-or-cross-runner", True)
        return ToolchainPlan(target, "ld.lld", "llvm-ar", "native", False)

    def artifact_name(self, basename: str, target_name: str) -> str:
        target = parse_target(target_name)
        return f"{basename}-{target.triple}{target.executable_suffix}"
PY

cat > tools/panther-toolchain/panther_toolchain/builder.py <<'PY'
from dataclasses import dataclass, asdict
from pathlib import Path
from .resolver import ToolchainResolver

@dataclass
class BuildArtifact:
    source: str
    target: str
    object_file: str
    executable: str
    linker: str
    status: str

class CrossPlatformBuilder:
    def __init__(self, build_dir: str = "build/cross"):
        self.build_dir = Path(build_dir)
        self.resolver = ToolchainResolver()

    def plan(self, source: str, target_name: str) -> BuildArtifact:
        plan = self.resolver.resolve(target_name)
        stem = Path(source).stem
        target_dir = self.build_dir / plan.target.triple
        obj = target_dir / f"{stem}{plan.target.object_suffix}"
        exe = target_dir / self.resolver.artifact_name(stem, target_name)
        return BuildArtifact(source, plan.target.triple, str(obj), str(exe), plan.linker, "planned")

    def emit_manifest(self, source: str, targets: list[str]) -> dict:
        artifacts = [asdict(self.plan(source, target)) for target in targets]
        return {"phase": "6.9", "source": source, "artifacts": artifacts, "status": "ok"}
PY

cat > tools/panther-toolchain/config/targets.json <<'JSON'
{
  "phase": "6.9",
  "name": "PantherLang Cross Platform Toolchain",
  "targets": [
    "linux-x86_64",
    "linux-aarch64",
    "macos-x86_64",
    "macos-aarch64",
    "windows-x86_64"
  ]
}
JSON

cat > tools/panther-toolchain/tests/test_cross_platform_toolchain.py <<'PY'
import json
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from panther_toolchain.targets import parse_target, TARGETS
from panther_toolchain.resolver import ToolchainResolver
from panther_toolchain.builder import CrossPlatformBuilder

class TestPantherCrossPlatformTargets(unittest.TestCase):
    def test_linux_target_triple(self):
        self.assertEqual(parse_target("linux-x86_64").triple, "x86_64-unknown-linux-gnu")

    def test_windows_suffixes(self):
        target = parse_target("windows-x86_64")
        self.assertEqual(target.executable_suffix, ".exe")
        self.assertEqual(target.object_suffix, ".obj")
        self.assertEqual(target.shared_library_suffix, ".dll")

    def test_macos_shared_library_suffix(self):
        self.assertEqual(parse_target("macos-aarch64").shared_library_suffix, ".dylib")

    def test_unsupported_target_rejected(self):
        with self.assertRaises(ValueError):
            parse_target("amiga-68000")

class TestPantherToolchainResolver(unittest.TestCase):
    def test_linux_uses_lld(self):
        plan = ToolchainResolver().resolve("linux-x86_64")
        self.assertEqual(plan.linker, "ld.lld")
        self.assertFalse(plan.sysroot_required)

    def test_windows_uses_lld_link(self):
        plan = ToolchainResolver().resolve("windows-x86_64")
        self.assertEqual(plan.linker, "lld-link")
        self.assertTrue(plan.sysroot_required)

    def test_artifact_name_windows(self):
        name = ToolchainResolver().artifact_name("hello", "windows-x86_64")
        self.assertTrue(name.endswith(".exe"))
        self.assertIn("x86_64-pc-windows-msvc", name)

class TestPantherCrossPlatformBuilder(unittest.TestCase):
    def test_builder_plan_contains_object_and_executable(self):
        artifact = CrossPlatformBuilder().plan("examples/hello.panther", "linux-x86_64")
        self.assertEqual(artifact.status, "planned")
        self.assertTrue(artifact.object_file.endswith(".o"))
        self.assertIn("x86_64-unknown-linux-gnu", artifact.executable)

    def test_manifest_covers_all_configured_targets(self):
        config = json.loads(Path("tools/panther-toolchain/config/targets.json").read_text())
        manifest = CrossPlatformBuilder().emit_manifest("examples/phase_6_9_toolchain/hello_cross.panther", config["targets"])
        self.assertEqual(manifest["phase"], "6.9")
        self.assertEqual(len(manifest["artifacts"]), len(TARGETS))
        self.assertEqual(manifest["status"], "ok")

    def test_manifest_has_cross_platform_linkers(self):
        manifest = CrossPlatformBuilder().emit_manifest("examples/phase_6_9_toolchain/hello_cross.panther", ["linux-x86_64", "windows-x86_64", "macos-aarch64"])
        linkers = {item["linker"] for item in manifest["artifacts"]}
        self.assertIn("ld.lld", linkers)
        self.assertIn("lld-link", linkers)
        self.assertIn("ld64.lld", linkers)

if __name__ == "__main__":
    unittest.main(verbosity=2)
PY

cat > examples/phase_6_9_toolchain/hello_cross.panther <<'PANTHER'
module hello_cross

fn main() -> int {
    print("PantherLang Phase 6.9 cross-platform toolchain")
    return 0
}
PANTHER

cat > docs/phase_6/PHASE_6_9_CROSS_PLATFORM_TOOLCHAIN.md <<'MD'
# PantherLang Phase 6.9 — Cross Platform Toolchain

This phase adds a cross-platform toolchain planning layer for PantherLang compiler integration.

## Targets

- linux-x86_64
- linux-aarch64
- macos-x86_64
- macos-aarch64
- windows-x86_64

## Added Components

- Target triple model
- Toolchain resolver
- Cross-platform artifact planner
- Target configuration
- Real unit tests
- Verification report generation
MD

cat > "$VERIFY" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

echo "[verify 6.9] Checking required files ..."
required=(
  "tools/panther-toolchain/panther_toolchain/__init__.py"
  "tools/panther-toolchain/panther_toolchain/targets.py"
  "tools/panther-toolchain/panther_toolchain/resolver.py"
  "tools/panther-toolchain/panther_toolchain/builder.py"
  "tools/panther-toolchain/config/targets.json"
  "tools/panther-toolchain/tests/test_cross_platform_toolchain.py"
  "examples/phase_6_9_toolchain/hello_cross.panther"
  "docs/phase_6/PHASE_6_9_CROSS_PLATFORM_TOOLCHAIN.md"
)
for f in "${required[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "ERROR: missing $f"
    exit 1
  fi
  echo "OK: $f"
done

echo
mkdir -p build/reports build/cross
export PYTHONPATH="tools/panther-toolchain:${PYTHONPATH:-}"

echo "[verify 6.9] Running Python unit tests ..."
set +e
python3 -m unittest discover -s tools/panther-toolchain/tests -p 'test_*.py' -v 2>&1 | tee build/reports/phase6_9_cross_platform_tests.log
test_status=${PIPESTATUS[0]}
set -e

if [[ "$test_status" -ne 0 ]]; then
  echo "ERROR: Phase 6.9 unit tests failed."
  exit 1
fi

if grep -q "Ran 0 tests" build/reports/phase6_9_cross_platform_tests.log; then
  echo "ERROR: No tests were executed."
  exit 1
fi

python3 - <<'PY'
import json
import re
from pathlib import Path
from panther_toolchain.builder import CrossPlatformBuilder

log = Path("build/reports/phase6_9_cross_platform_tests.log").read_text()
match = re.search(r"Ran (\d+) tests", log)
tests = int(match.group(1)) if match else 0
config = json.loads(Path("tools/panther-toolchain/config/targets.json").read_text())
manifest = CrossPlatformBuilder().emit_manifest("examples/phase_6_9_toolchain/hello_cross.panther", config["targets"])
report = {
    "phase": "6.9",
    "name": "Cross Platform Toolchain",
    "status": "PASS",
    "tests_run": tests,
    "targets": config["targets"],
    "manifest": manifest,
}
Path("build/reports/phase6_9_cross_platform_toolchain_report.json").write_text(json.dumps(report, indent=2))
print("Report written: build/reports/phase6_9_cross_platform_toolchain_report.json")
PY

echo
echo "Phase 6.9 cross-platform toolchain verification completed successfully."
SH

chmod +x "$VERIFY"

echo "[PantherLang 6.9] Running Phase 6.9 verification ..."
bash "$VERIFY"

echo
echo "============================================================"
echo "PantherLang Phase 6.9 bootstrap finished"
echo "============================================================"
echo "Reports: build/reports/phase6_9_cross_platform_toolchain_report.json"
echo "Next: Phase 6.10 — Final Compiler Integration"
