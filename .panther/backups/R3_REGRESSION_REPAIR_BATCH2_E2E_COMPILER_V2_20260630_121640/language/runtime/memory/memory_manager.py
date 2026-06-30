class PantherMemoryManager:
    def __init__(self):
        self.objects = {}
        self.next_id = 1

    def allocate(self, obj):
        object_id = self.next_id
        self.objects[object_id] = obj
        self.next_id += 1
        return object_id

    def get(self, object_id):
        return self.objects.get(object_id)

    def release(self, object_id):
        return self.objects.pop(object_id, None) is not None

    def stats(self):
        return {
            "allocated": len(self.objects),
            "next_id": self.next_id,
        }
