class VariableReferenceAllocator:
    def __init__(self):
        self._next = 1
        self._objects = {}

    def allocate(self, value):
        ref = self._next
        self._next += 1
        self._objects[ref] = value
        return ref

    def get(self, ref):
        return self._objects.get(ref)

    def has(self, ref):
        return ref in self._objects
