#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 1.16–1.20 — Final Phase One Bootstrap"
echo "Root: $(pwd)"

mkdir -p \
  language/runtime \
  language/repl \
  language/registry \
  language/ide \
  language/tests \
  scripts \
  docs \
  architecture/runtime \
  architecture/tools \
  releases

# =========================
# 1.16 Runtime
# =========================

cat > architecture/runtime/RUNTIME.md <<'EOF'
# Panther Runtime — Phase 1.16

## Purpose
The Panther Runtime executes compiled Panther IR and generated artifacts.

## Phase 1.16 Scope
- Runtime context
- Runtime app registry
- Model registry
- Basic execution result

## Future Scope
- Panther VM
- Native runtime
- Web runtime
- Cloud runtime
- AI runtime
EOF

cat > language/runtime/panther_runtime.py <<'EOF'
class PantherRuntimeContext:
    def __init__(self, app_name="PantherApp"):
        self.app_name = app_name
        self.models = {}
        self.state = {}

    def register_model(self, name, fields):
        self.models[name] = fields

    def describe(self):
        return {
            "app": self.app_name,
            "models": self.models,
            "state": self.state,
        }


class PantherRuntime:
    def __init__(self, context=None):
        self.context = context or PantherRuntimeContext()

    def run(self):
        return {
            "status": "running",
            "app": self.context.app_name,
            "models": list(self.context.models.keys()),
        }
EOF

cat > language/runtime/__init__.py <<'EOF'
from .panther_runtime import PantherRuntime, PantherRuntimeContext
EOF

cat > language/tests/test_phase1_16_runtime.py <<'EOF'
from language.runtime import PantherRuntime, PantherRuntimeContext

ctx = PantherRuntimeContext("PantherStore")
ctx.register_model("Product", ["id", "title", "price"])

runtime = PantherRuntime(ctx)
result = runtime.run()

assert result["status"] == "running"
assert result["app"] == "PantherStore"
assert "Product" in result["models"]

print("✅ Phase 1.16 runtime tests passed.")
EOF

# =========================
# 1.17 REPL
# =========================

cat > architecture/tools/REPL.md <<'EOF'
# Panther REPL — Phase 1.17

## Purpose
The REPL provides an interactive shell for PantherLang.

## Phase 1.17 Scope
- Evaluate simple commands
- Provide version
- Provide help
EOF

cat > language/repl/panther_repl.py <<'EOF'
class PantherREPL:
    def evaluate(self, command: str):
        command = command.strip()

        if command in ("help", "?"):
            return "Panther REPL commands: help, version, exit"

        if command == "version":
            return "PantherLang Developer Preview v0.5"

        if command == "exit":
            return "exit"

        return f"echo: {command}"
EOF

cat > language/repl/__init__.py <<'EOF'
from .panther_repl import PantherREPL
EOF

cat > language/tests/test_phase1_17_repl.py <<'EOF'
from language.repl import PantherREPL

repl = PantherREPL()

assert "Developer Preview" in repl.evaluate("version")
assert "commands" in repl.evaluate("help")
assert repl.evaluate("hello") == "echo: hello"

print("✅ Phase 1.17 REPL tests passed.")
EOF

# =========================
# 1.18 Registry
# =========================

cat > architecture/tools/REGISTRY.md <<'EOF'
# Panther Registry — Phase 1.18

## Purpose
The Panther Registry tracks packages available to Panther projects.

## Phase 1.18 Scope
- Local package registry
- Register package
- List packages
- Resolve package
EOF

cat > language/registry/panther_registry.py <<'EOF'
class PantherRegistry:
    def __init__(self):
        self.packages = {}

    def register(self, name, version="0.1.0"):
        self.packages[name] = version
        return True

    def list_packages(self):
        return dict(self.packages)

    def resolve(self, name):
        return self.packages.get(name)
EOF

cat > language/registry/__init__.py <<'EOF'
from .panther_registry import PantherRegistry
EOF

cat > language/tests/test_phase1_18_registry.py <<'EOF'
from language.registry import PantherRegistry

registry = PantherRegistry()
registry.register("panther.core", "0.5")
registry.register("panther.ai", "0.5")

assert registry.resolve("panther.core") == "0.5"
assert "panther.ai" in registry.list_packages()

print("✅ Phase 1.18 registry tests passed.")
EOF

# =========================
# 1.19 IDE Protocol
# =========================

cat > architecture/tools/IDE_PROTOCOL.md <<'EOF'
# Panther IDE Protocol — Phase 1.19

## Purpose
The IDE Protocol prepares PantherLang for editor integrations.

## Phase 1.19 Scope
- Diagnostics protocol
- Completion protocol
- Symbol protocol

## Future Scope
- LSP server
- VS Code extension
- JetBrains plugin
- Panther Studio
EOF

cat > language/ide/protocol.py <<'EOF'
class PantherIDEProtocol:
    def diagnostics(self, source: str):
        if "???" in source:
            return [{"level": "error", "message": "Unknown syntax marker"}]
        return []

    def completions(self, prefix: str):
        keywords = ["app", "model", "api", "page", "agent", "workflow", "capabilities"]
        return [k for k in keywords if k.startswith(prefix)]

    def symbols(self, source: str):
        found = []
        for line in source.splitlines():
            clean = line.strip()
            if clean.startswith("model "):
                found.append({"kind": "model", "name": clean.split()[1]})
            if clean.startswith("app "):
                found.append({"kind": "app", "name": clean.split()[1]})
        return found
EOF

cat > language/ide/__init__.py <<'EOF'
from .protocol import PantherIDEProtocol
EOF

cat > language/tests/test_phase1_19_ide.py <<'EOF'
from language.ide import PantherIDEProtocol

ide = PantherIDEProtocol()

assert ide.diagnostics("app Demo {}") == []
assert ide.diagnostics("???")[0]["level"] == "error"
assert "model" in ide.completions("mo")

symbols = ide.symbols("app PantherStore {\\nmodel Product {\\n")
assert symbols[0]["kind"] == "app"
assert symbols[1]["name"] == "Product"

print("✅ Phase 1.19 IDE protocol tests passed.")
EOF

# =========================
# 1.20 Alpha Release
# =========================

cat > docs/PHASE_1_COMPLETE.md <<'EOF'
# PantherLang Phase 1 Complete

## Release
PantherLang Developer Preview v0.5

## Completed Modules
- 1.1 Foundation
- 1.2 Lexer
- 1.3 Parser
- 1.4 Semantic Engine
- 1.5 IR Engine
- 1.6 Code Generator
- 1.7 First Compiler
- 1.8 Official Language Specification
- 1.9 Standard Library
- 1.10 CLI
- 1.11 Package Manager
- 1.12 Formatter
- 1.13 Documentation Generator
- 1.14 Testing Framework
- 1.15 Project Builder
- 1.16 Runtime
- 1.17 REPL
- 1.18 Registry
- 1.19 IDE Protocol
- 1.20 Alpha Release

## Status
Phase One is complete and ready for Developer Preview packaging.
EOF

cat > releases/PANTHERLANG_DEVELOPER_PREVIEW_v0_5.md <<'EOF'
# PantherLang Developer Preview v0.5

## Status
Developer Preview

## Summary
This release completes PantherLang Phase 1 foundation.

## Includes
Compiler foundation, runtime foundation, standard library foundation, CLI, package manager, formatter, documentation generator, testing framework, project builder, REPL, registry, and IDE protocol foundation.
EOF

cat > scripts/verify_phase1_final.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_16_runtime.py
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_17_repl.py
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_18_registry.py
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase1_19_ide.py

test -f docs/PHASE_1_COMPLETE.md
test -f releases/PANTHERLANG_DEVELOPER_PREVIEW_v0_5.md

echo "✅ PantherLang Phase 1.16–1.20 final verification complete."
EOF

chmod +x scripts/verify_phase1_final.sh

bash scripts/verify_phase1_final.sh

echo "--------------------------------"
echo "✅ PantherLang Phase 1.16–1.20 installed successfully."
echo "✅ PantherLang Phase One is complete."
echo "Run anytime: bash scripts/verify_phase1_final.sh"
echo "Release doc: releases/PANTHERLANG_DEVELOPER_PREVIEW_v0_5.md"
echo "--------------------------------"
