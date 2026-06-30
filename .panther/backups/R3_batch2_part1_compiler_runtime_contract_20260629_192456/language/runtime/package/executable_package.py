class PantherExecutablePackage:
    def __init__(self, name, runtime_program):
        self.name = name
        self.runtime_program = runtime_program

    def manifest(self):
        return {
            "name": self.name,
            "runtime": "PantherRuntime",
            "program": self.runtime_program,
        }
