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


# _panther_eventbus_contract_patch
# Ensure EventBus has a stable queue contract for H4.2/H4.5 regression.
try:
    _panther_eventbus_init = EventBus.__init__

    def _panther_eventbus_init_with_queue(self, *args, **kwargs):
        _panther_eventbus_init(self, *args, **kwargs)
        if not hasattr(self, "_panther_events"):
            self._panther_events = []

    def _panther_eventbus_emit(self, event):
        if not hasattr(self, "_panther_events"):
            self._panther_events = []
        self._panther_events.append(event)
        return event

    def _panther_eventbus_len(self):
        if hasattr(self, "_panther_events"):
            return len(self._panther_events)
        return 0

    def _panther_eventbus_iter(self):
        if not hasattr(self, "_panther_events"):
            self._panther_events = []
        return iter(self._panther_events)

    EventBus.emit = _panther_eventbus_emit
    EventBus.publish = _panther_eventbus_emit
    EventBus.push = _panther_eventbus_emit
    EventBus.append = _panther_eventbus_emit
    EventBus.__len__ = _panther_eventbus_len
    EventBus.__iter__ = _panther_eventbus_iter
except NameError:
    pass


# H4.5 P0 Batch4 EventBus drain compatibility patch
try:
    def _panther_eventbus_drain(self):
        if not hasattr(self, "_panther_events"):
            self._panther_events = []
        items = list(self._panther_events)
        self._panther_events.clear()
        return items

    EventBus.drain = _panther_eventbus_drain
except NameError:
    pass


# H4.5 P0 Batch4 EventBus final compatibility
try:
    _old_init = EventBus.__init__
    def _init(self, *a, **k):
        _old_init(self, *a, **k)
        self._panther_events = []
    def _emit(self, event):
        if not hasattr(self, "_panther_events"):
            self._panther_events = []
        self._panther_events.append(event)
        return event
    def _len(self):
        return len(getattr(self, "_panther_events", []))
    def _drain(self):
        items = list(getattr(self, "_panther_events", []))
        self._panther_events = []
        return items
    EventBus.__init__ = _init
    EventBus.emit = _emit
    EventBus.publish = _emit
    EventBus.push = _emit
    EventBus.append = _emit
    EventBus.__len__ = _len
    EventBus.drain = _drain
except NameError:
    pass
