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
