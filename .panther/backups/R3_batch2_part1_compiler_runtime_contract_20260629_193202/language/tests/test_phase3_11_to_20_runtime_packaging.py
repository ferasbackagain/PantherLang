from pathlib import Path

from language.runtime.cli import PantherRuntimeCLI
from language.runtime.config import PantherRuntimeConfig
from language.runtime.logging import PantherRuntimeLogger
from language.runtime.permissions import PantherPermissionEngine
from language.runtime.services import PantherServiceContainer
from language.runtime.packager import PantherExecutablePackager
from language.runtime.packager.artifact_loader import PantherArtifactLoader
from language.runtime.vm.runtime_pipeline import PantherRuntimePipeline

source = open("language/examples/phase2_full_system.panther").read()

# 3.11 CLI
cli = PantherRuntimeCLI()
assert cli.doctor() == "Panther Runtime CLI OK"
assert "PantherStore" in cli.run_source(source)

# 3.12 Config
cfg = PantherRuntimeConfig()
cfg.set("port", 7777)
assert cfg.get("port") == 7777
assert cfg.to_dict()["mode"] == "development"

# 3.13 Logger
logger = PantherRuntimeLogger()
logger.info("runtime started")
logger.warning("runtime warning")
assert logger.all()[0]["level"] == "info"
assert logger.all()[1]["level"] == "warning"

# 3.14 Permissions
perm = PantherPermissionEngine()
perm.allow("filesystem.read")
assert perm.check("filesystem.read") is True
perm.require("filesystem.read")

# 3.15 Services
services = PantherServiceContainer()
services.register("logger", logger)
assert services.resolve("logger") is logger
assert "logger" in services.list_services()

# 3.16 + 3.17 Packaging and artifact loading
runtime_program = PantherRuntimePipeline().compile_to_runtime_program(source)
pkg_path = PantherExecutablePackager().package("PantherStore", runtime_program)
assert Path(pkg_path).exists()

artifact = PantherArtifactLoader().load(pkg_path)
assert artifact["name"] == "PantherStore"
assert artifact["runtime"] == "PantherRuntime"
assert "Product" in artifact["runtime_program"]["models"]

print("✅ Phase 3.11–3.20 runtime CLI + packaging tests passed.")
