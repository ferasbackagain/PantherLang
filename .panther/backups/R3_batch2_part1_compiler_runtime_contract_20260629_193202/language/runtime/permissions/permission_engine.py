class PantherPermissionEngine:
    def __init__(self):
        self.allowed = set()

    def allow(self, capability):
        self.allowed.add(capability)

    def deny(self, capability):
        self.allowed.discard(capability)

    def check(self, capability):
        return capability in self.allowed

    def require(self, capability):
        if not self.check(capability):
            raise PermissionError(f"Capability denied: {capability}")
        return True
