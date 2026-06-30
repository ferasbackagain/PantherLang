from language.registry import PantherRegistry

registry = PantherRegistry()
registry.register("panther.core", "0.5")
registry.register("panther.ai", "0.5")

assert registry.resolve("panther.core") == "0.5"
assert "panther.ai" in registry.list_packages()

print("✅ Phase 1.18 registry tests passed.")
