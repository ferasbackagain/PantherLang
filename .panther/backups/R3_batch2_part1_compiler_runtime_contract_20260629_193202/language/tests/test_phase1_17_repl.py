from language.repl import PantherREPL

repl = PantherREPL()

assert "Developer Preview" in repl.evaluate("version")
assert "commands" in repl.evaluate("help")
assert repl.evaluate("hello") == "echo: hello"

print("✅ Phase 1.17 REPL tests passed.")
