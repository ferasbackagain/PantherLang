from language.runtime import PantherRuntime, PantherRuntimeContext

ctx = PantherRuntimeContext("PantherStore")
ctx.register_model("Product", ["id", "title", "price"])

runtime = PantherRuntime(ctx)
result = runtime.run()

assert result["status"] == "running"
assert result["app"] == "PantherStore"
assert "Product" in result["models"]

print("✅ Phase 1.16 runtime tests passed.")
