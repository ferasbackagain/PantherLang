from language.ide import PantherIDEProtocol

ide = PantherIDEProtocol()

assert ide.diagnostics("app Demo {}") == []
assert ide.diagnostics("???")[0]["level"] == "error"
assert "model" in ide.completions("mo")

symbols = ide.symbols("app PantherStore {\nmodel Product {\n")
assert symbols[0]["kind"] == "app"
assert symbols[1]["name"] == "Product"

print("✅ Phase 1.19 IDE protocol tests passed.")
