from language.tools.formatter import format_panther

source = "app PantherStore {   \nmodel Product { \n id: uuid\n}\n}\n"
formatted = format_panther(source)

assert formatted.endswith("\n")
assert "app PantherStore {" in formatted
assert "    model Product {" in formatted
assert "        id: uuid" in formatted
assert formatted.count("\n\n\n") == 0

print("✅ Phase 1.12 formatter tests passed.")
