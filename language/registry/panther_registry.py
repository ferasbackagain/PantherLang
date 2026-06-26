class PantherRegistry:
    def __init__(self):
        self.packages = {}

    def register(self, name, version="0.1.0"):
        self.packages[name] = version
        return True

    def list_packages(self):
        return dict(self.packages)

    def resolve(self, name):
        return self.packages.get(name)
