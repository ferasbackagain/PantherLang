#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 3.11–3.20 — Runtime CLI + Packaging Bootstrap"
echo "Root: $(pwd)"

mkdir -p \
  architecture/phase3 \
  language/runtime/config \
  language/runtime/logging \
  language/runtime/permissions \
  language/runtime/services \
  language/runtime/packager \
  language/runtime/cli \
  language/runtime/artifacts \
  language/tests \
  scripts \
  docs \
  releases

# =========================
# Phase 3.11 Runtime CLI Integration
# =========================

cat > language/runtime/cli/runtime_cli.py <<'EOF'
from language.runtime.vm import PantherRuntimePipeline


class PantherRuntimeCLI:
    def run_source(self, source):
        result = PantherRuntimePipeline().execute_source(source)
        return f"Executed {result['app']} with models: {', '.join(result['models'])}"

    def doctor(self):
        return "Panther Runtime CLI OK"
EOF

cat > language/runtime/cli/__init__.py <<'EOF'
from .runtime_cli import PantherRuntimeCLI
EOF

# =========================
# Phase 3.12 Runtime Config
# =========================

cat > language/runtime/config/runtime_config.py <<'EOF'
class PantherRuntimeConfig:
    def __init__(self, mode="development", debug=True):
        self.mode = mode
        self.debug = debug
        self.settings = {}

    def set(self, key, value):
        self.settings[key] = value

    def get(self, key, default=None):
        return self.settings.get(key, default)

    def to_dict(self):
        return {
            "mode": self.mode,
            "debug": self.debug,
            "settings": self.settings,
        }
EOF

cat > language/runtime/config/__init__.py <<'EOF'
from .runtime_config import PantherRuntimeConfig
EOF

# =========================
# Phase 3.13 Runtime Logger
# =========================

cat > language/runtime/logging/runtime_logger.py <<'EOF'
class PantherRuntimeLogger:
    def __init__(self):
        self.logs = []

    def info(self, message):
        self.logs.append({"level": "info", "message": message})

    def warning(self, message):
        self.logs.append({"level": "warning", "message": message})

    def error(self, message):
        self.logs.append({"level": "error", "message": message})

    def all(self):
        return list(self.logs)
EOF

cat > language/runtime/logging/__init__.py <<'EOF'
from .runtime_logger import PantherRuntimeLogger
EOF

# =========================
# Phase 3.14 Runtime Permissions
# =========================

cat > language/runtime/permissions/permission_engine.py <<'EOF'
class PantherPermissionEngine:
    def __init__(self):
        self.allowed = set()

    def allow(self, capability):
        self.allowed.add(capability)

    def deny(self, capability):
        self.allowed.discard(capability)

    def check(self, capability):
        return capability in self.allowed

    def require(self, capability):
        if not self.check(capability):
            raise PermissionError(f"Capability denied: {capability}")
        return True
EOF

cat > language/runtime/permissions/__init__.py <<'EOF'
from .permission_engine import PantherPermissionEngine
EOF

# =========================
# Phase 3.15 Runtime Services
# =========================

cat > language/runtime/services/service_container.py <<'EOF'
class PantherServiceContainer:
    def __init__(self):
        self.services = {}

    def register(self, name, service):
        self.services[name] = service
        return True

    def resolve(self, name):
        if name not in self.services:
            raise KeyError(f"Service not found: {name}")
        return self.services[name]

    def list_services(self):
        return sorted(self.services.keys())
EOF

cat > language/runtime/services/__init__.py <<'EOF'
from .service_container import PantherServiceContainer
EOF

# =========================
# Phase 3.16 Executable Packager
# =========================

cat > language/runtime/packager/executable_packager.py <<'EOF'
import json
from pathlib import Path


class PantherExecutablePackager:
    def package(self, name, runtime_program, output_dir="language/runtime/artifacts"):
        out = Path(output_dir)
        out.mkdir(parents=True, exist_ok=True)
        manifest = {
            "name": name,
            "type": "panther-executable-package",
            "runtime": "PantherRuntime",
            "runtime_program": runtime_program,
        }
        path = out / f"{name}.pantherpkg.json"
        path.write_text(json.dumps(manifest, indent=2) + "\n")
        return path
EOF

cat > language/runtime/packager/__init__.py <<'EOF'
from .executable_packager import PantherExecutablePackager
EOF

# =========================
# Phase 3.17 Runtime Artifact Loader
# =========================

cat > language/runtime/packager/artifact_loader.py <<'EOF'
import json
from pathlib import Path


class PantherArtifactLoader:
    def load(self, path):
        return json.loads(Path(path).read_text())
EOF

# =========================
# Phase 3.18 Runtime Release Manifest
# =========================

cat > releases/PANTHER_RUNTIME_PHASE3_MANIFEST.md <<'EOF'
# Panther Runtime Phase 3 Manifest

## Completed
- 3.1 Runtime Execution Engine
- 3.2 Runtime Object Model
- 3.3 Memory Manager
- 3.4 Module Loader
- 3.5 Native Function Bridge
- 3.6 Runtime Error System
- 3.7 Debug Trace System
- 3.8 Runtime Optimizer Stub
- 3.9 Executable Package Model
- 3.10 End-to-End Runtime Execution
- 3.11 Runtime CLI Integration
- 3.12 Runtime Config
- 3.13 Runtime Logger
- 3.14 Runtime Permissions
- 3.15 Runtime Services
- 3.16 Executable Packager
- 3.17 Artifact Loader
- 3.18 Runtime Release Manifest
- 3.19 Runtime Verification Suite
- 3.20 Phase 3 Runtime Complete
EOF

# =========================
# Phase 3.19 Verification Suite
# =========================

cat > language/tests/test_phase3_11_to_20_runtime_packaging.py <<'EOF'
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
EOF

# =========================
# Phase 3.20 Docs + Verify
# =========================

cat > docs/PHASE_3_COMPLETE.md <<'EOF'
# PantherLang Phase 3 Complete

## Result
PantherLang now has a runtime execution foundation.

## Completed Capability
- Compile `.panther` source into runtime program.
- Execute runtime program.
- Manage runtime objects and memory.
- Load modules.
- Bridge native functions.
- Trace debug events.
- Package executable runtime artifacts.
- Provide runtime CLI foundation.
- Provide runtime config, logging, permissions, and services.

## Next
Phase 4 — Real Developer Experience:
- CLI command integration
- Project commands
- Real `panther run`
- Real `panther build`
- Error reporting
- Source maps
- Better diagnostics
EOF

cat > scripts/verify_phase3_11_to_20.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase3_11_to_20_runtime_packaging.py
test -f docs/PHASE_3_COMPLETE.md
test -f releases/PANTHER_RUNTIME_PHASE3_MANIFEST.md
echo "✅ PantherLang Phase 3.11–3.20 verification complete."
EOF

chmod +x scripts/verify_phase3_11_to_20.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase3_11_to_20_runtime_packaging.py

echo "--------------------------------"
echo "✅ PantherLang Phase 3.11–3.20 installed successfully."
echo "Run anytime: bash scripts/verify_phase3_11_to_20.sh"
echo "Phase 3 complete."
echo "--------------------------------"
