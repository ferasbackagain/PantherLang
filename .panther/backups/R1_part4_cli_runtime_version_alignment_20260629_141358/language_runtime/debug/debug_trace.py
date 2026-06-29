class PantherDebugTrace:
    def __init__(self):
        self.events = []

    def add(self, event, data=None):
        self.events.append({
            "event": event,
            "data": data or {},
        })

    def all(self):
        return list(self.events)

    def clear(self):
        self.events.clear()
