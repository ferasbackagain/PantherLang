class PantherModuleLoader:
    def __init__(self):
        self.modules = {}

    def register(self, name, module):
        self.modules[name] = module
        return True

    def load(self, name):
        if name not in self.modules:
            raise ImportError(f"Panther module not found: {name}")
        return self.modules[name]

    def list_modules(self):
        return sorted(self.modules.keys())
