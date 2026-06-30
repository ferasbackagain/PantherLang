class WatchExpressionStore:
    def __init__(self):
        self._items = []

    def add(self, expression):
        if expression not in self._items:
            self._items.append(expression)
        return expression

    def remove(self, expression):
        if expression in self._items:
            self._items.remove(expression)

    def list(self):
        return list(self._items)
