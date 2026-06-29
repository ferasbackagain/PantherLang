class PantherServiceContainer:
    def __init__(self):
        self.services = {}

    def register(self, name, service):
        self.services[name] = service
        return True

    def resolve(self, name):
        if name not in self.services:
            raise KeyError(f"Service not found: {name}")
        return self.services[name]

    def list_services(self):
        return sorted(self.services.keys())
