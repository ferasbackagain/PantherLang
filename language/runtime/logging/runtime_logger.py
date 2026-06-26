class PantherRuntimeLogger:
    def __init__(self):
        self.logs = []

    def info(self, message):
        self.logs.append({"level": "info", "message": message})

    def warning(self, message):
        self.logs.append({"level": "warning", "message": message})

    def error(self, message):
        self.logs.append({"level": "error", "message": message})

    def all(self):
        return list(self.logs)
