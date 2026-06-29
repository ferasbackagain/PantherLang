from collections import deque


class EventBus:
    def __init__(self):
        self._queue = deque()

    def publish(self, event):
        self._queue.append(event)
        return event

    def drain(self):
        events = list(self._queue)
        self._queue.clear()
        return events

    def peek(self):
        return list(self._queue)

    def __len__(self):
        return len(self._queue)
