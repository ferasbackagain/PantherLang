class PantherNativeBridge:
    def __init__(self):
        self.functions = {}

    def register_function(self, name, fn):
        self.functions[name] = fn
        return True

    def call(self, name, *args, **kwargs):
        if name not in self.functions:
            raise NameError(f"Native function not found: {name}")
        return self.functions[name](*args, **kwargs)
