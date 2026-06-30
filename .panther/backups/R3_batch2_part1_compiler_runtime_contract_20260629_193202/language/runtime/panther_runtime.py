class PantherRuntimeContext:
    def __init__(self, app_name="PantherApp"):
        self.app_name = app_name
        self.models = {}
        self.state = {}

    def register_model(self, name, fields):
        self.models[name] = fields

    def describe(self):
        return {
            "app": self.app_name,
            "models": self.models,
            "state": self.state,
        }


class PantherRuntime:
    def __init__(self, context=None):
        self.context = context or PantherRuntimeContext()

    def run(self):
        return {
            "status": "running",
            "app": self.context.app_name,
            "models": list(self.context.models.keys()),
        }
