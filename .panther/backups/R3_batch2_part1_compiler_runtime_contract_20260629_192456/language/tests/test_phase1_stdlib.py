from language.stdlib.core import identity, type_of
from language.stdlib.math import add, divide
from language.stdlib.string import upper, trim
from language.stdlib.collections import count, first, unique
from language.stdlib.json import parse, stringify
from language.stdlib.http import ok
from language.stdlib.security import deny_by_default
from language.stdlib.ai import AgentSpec

assert identity("Panther") == "Panther"
assert type_of(123) == "int"
assert add(2, 3) == 5
assert divide(10, 2) == 5
assert upper("panther") == "PANTHER"
assert trim("  ai  ") == "ai"
assert count([1, 2, 3]) == 3
assert first(["a", "b"]) == "a"
assert unique([1, 1, 2]) == [1, 2]
assert parse('{"x":1}')["x"] == 1
assert "x" in stringify({"x": 1})
assert ok({"ready": True})["status"] == 200
assert deny_by_default() is True
assert AgentSpec("Assistant", "Help users", ["data"], "scoped").to_dict()["memory"] == "scoped"

print("✅ Phase 1.9 standard library tests passed.")
