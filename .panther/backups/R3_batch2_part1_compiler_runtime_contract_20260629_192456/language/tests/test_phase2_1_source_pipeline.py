from language.compiler.pipeline import PantherSourcePipeline

pipeline = PantherSourcePipeline()
result = pipeline.run_file("language/examples/phase2_panther_store.panther")

assert result["source_length"] > 0
assert result["token_count"] > 10
assert result["parsed"]["node"] == "Program"
assert "PantherStore" in result["parsed"]["tokens"]
assert "Product" in result["parsed"]["tokens"]

print("✅ Phase 2.1 source pipeline tests passed.")
