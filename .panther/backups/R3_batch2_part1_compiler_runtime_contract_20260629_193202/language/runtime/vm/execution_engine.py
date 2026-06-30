class RuntimeExecutionEngine:
    def __init__(self):
        self.loaded_program = None

    def load(self, runtime_program):
        self.loaded_program = runtime_program
        return True

    def execute(self):
        if self.loaded_program is None:
            raise RuntimeError("No runtime program loaded")

        return {
            "status": "executed",
            "app": self.loaded_program.get("app", "PantherApp"),
            "models": list(self.loaded_program.get("models", {}).keys()),
        }
