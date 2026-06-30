from language.runtime.vm import RuntimeExecutionEngine, PantherObject, PantherRuntimePipeline
from language.runtime.memory import PantherMemoryManager
from language.runtime.modules import PantherModuleLoader
from language.runtime.native import PantherNativeBridge
from language.runtime.debug import PantherDebugTrace
from language.runtime.package import PantherExecutablePackage

# 3.1 Execution Engine
engine = RuntimeExecutionEngine()
engine.load({"app": "PantherStore", "models": {"Product": ["id", "title"]}})
result = engine.execute()
assert result["status"] == "executed"
assert result["app"] == "PantherStore"
assert "Product" in result["models"]

# 3.2 Object Model
obj = PantherObject("Product", {"title": "Laptop"})
obj.set("price", 100)
assert obj.get("title") == "Laptop"
assert obj.to_dict()["fields"]["price"] == 100

# 3.3 Memory Manager
mem = PantherMemoryManager()
oid = mem.allocate(obj)
assert mem.get(oid).get("title") == "Laptop"
assert mem.stats()["allocated"] == 1
assert mem.release(oid) is True

# 3.4 Module Loader
loader = PantherModuleLoader()
loader.register("panther.core", {"ok": True})
assert loader.load("panther.core")["ok"] is True
assert "panther.core" in loader.list_modules()

# 3.5 Native Bridge
bridge = PantherNativeBridge()
bridge.register_function("add", lambda a, b: a + b)
assert bridge.call("add", 2, 3) == 5

# 3.7 Debug Trace
trace = PantherDebugTrace()
trace.add("runtime.start", {"app": "PantherStore"})
assert trace.all()[0]["event"] == "runtime.start"

# 3.9 Executable Package
pkg = PantherExecutablePackage("PantherStore", {"app": "PantherStore"})
assert pkg.manifest()["name"] == "PantherStore"

# 3.10 End-to-End Runtime Pipeline
source = open("language/examples/phase2_full_system.panther").read()
runtime_result = PantherRuntimePipeline().execute_source(source)
assert runtime_result["status"] == "executed"
assert runtime_result["app"] == "PantherStore"
assert "Product" in runtime_result["models"]

print("✅ Phase 3.1–3.10 runtime execution tests passed.")
