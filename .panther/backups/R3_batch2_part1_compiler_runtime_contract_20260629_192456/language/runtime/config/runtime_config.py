class PantherRuntimeConfig:
    def __init__(self, mode="development", debug=True):
        self.mode = mode
        self.debug = debug
        self.settings = {}

    def set(self, key, value):
        self.settings[key] = value

    def get(self, key, default=None):
        return self.settings.get(key, default)

    def to_dict(self):
        return {
            "mode": self.mode,
            "debug": self.debug,
            "settings": self.settings,
        }
