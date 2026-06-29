from .event_merge import EventMergeEngine


class EventDispatcher:
    """
    Compatibility facade backed by the H4.2 F5 event merge engine.

    This keeps the newer F5 canonical event layer while preserving the exact
    calling contract already used by DebugServer and Part2B v2 regression.
    """

    def __init__(self, engine=None):
        self.engine = engine or EventMergeEngine()

    def event(self, name, body=None):
        return self.engine.event(name, body or {})

    def initialized(self):
        return self.engine.initialized()

    def process(
        self,
        name="PantherLang Program",
        pid=0,
        system_process_id=None,
        command=None,
        state=None,
        execution=None,
        start_method="launch",
        **extra,
    ):
        body = {
            "name": name,
            "systemProcessId": int(system_process_id if system_process_id is not None else (pid or 0)),
            "isLocalProcess": True,
            "startMethod": start_method,
        }

        if command is not None:
            body["command"] = command
        if state is not None:
            body["state"] = state
        if execution is not None:
            body["execution"] = execution
        if extra:
            body.update(extra)

        return self.engine.event("process", body)

    def continued(
        self,
        thread_id=1,
        all_threads_continued=True,
        status=None,
        reason=None,
        source_command=None,
        **extra,
    ):
        body = {
            "threadId": int(thread_id),
            "allThreadsContinued": bool(all_threads_continued),
        }

        if status is not None:
            body["status"] = status
        if reason is not None:
            body["reason"] = reason
        if source_command is not None:
            body["sourceCommand"] = source_command
        if extra:
            body.update(extra)

        return self.engine.event("continued", body)

    def stopped(
        self,
        reason="pause",
        thread_id=1,
        all_threads_stopped=True,
        status=None,
        source_command=None,
        **extra,
    ):
        body = {
            "reason": reason,
            "threadId": int(thread_id),
            "allThreadsStopped": bool(all_threads_stopped),
        }

        if status is not None:
            body["status"] = status
        if source_command is not None:
            body["sourceCommand"] = source_command
        if extra:
            body.update(extra)

        return self.engine.event("stopped", body)

    def terminated(self, restart=False, **extra):
        if restart or extra:
            body = {}
            if restart:
                body["restart"] = True
            body.update(extra)
            return self.engine.event("terminated", body)
        return self.engine.terminated()

    def exited(self, exit_code=0, **extra):
        body = {"exitCode": int(exit_code)}
        if extra:
            body.update(extra)
        return self.engine.event("exited", body)

    def output(self, output, category="console", **extra):
        body = {
            "category": category,
            "output": str(output),
        }
        if extra:
            body.update(extra)
        return self.engine.event("output", body)


# H4.5 P0 Batch4 compatibility patch:
# Preserve request_seq and always emit into EventBus.
try:
    _panther_original_process = EventDispatcher.process

    def _panther_process_with_request_seq(self, *args, **kwargs):
        request_seq = kwargs.get("request_seq")
        event = _panther_original_process(self, *args, **kwargs)

        if isinstance(event, dict):
            if request_seq is not None:
                event["request_seq"] = request_seq

            bus = getattr(self, "bus", None)
            if bus is not None:
                if hasattr(bus, "emit"):
                    bus.emit(event)
                elif hasattr(bus, "publish"):
                    bus.publish(event)
                elif hasattr(bus, "push"):
                    bus.push(event)
                elif hasattr(bus, "append"):
                    bus.append(event)

        return event

    EventDispatcher.process = _panther_process_with_request_seq
except NameError:
    pass


# H4.5 P0 Batch4 EventDispatcher constructor bus patch
try:
    _panther_original_eventdispatcher_init = EventDispatcher.__init__

    def _panther_eventdispatcher_init_with_bus(self, *args, **kwargs):
        if args:
            self.bus = args[0]
        elif "bus" in kwargs:
            self.bus = kwargs["bus"]
        else:
            self.bus = None
        _panther_original_eventdispatcher_init(self, *args, **kwargs)
        if args:
            self.bus = args[0]
        elif "bus" in kwargs:
            self.bus = kwargs["bus"]

    EventDispatcher.__init__ = _panther_eventdispatcher_init_with_bus
except NameError:
    pass


# H4.5 P0 Batch4 EventDispatcher final compatibility
try:
    _old_init = EventDispatcher.__init__
    def _init(self, *a, **k):
        self.bus = a[0] if a else k.get("bus")
        _old_init(self, *a, **k)
        if a:
            self.bus = a[0]
        elif "bus" in k:
            self.bus = k["bus"]

    _old_process = EventDispatcher.process
    def _process(self, *a, **k):
        request_seq = k.get("request_seq")
        event = _old_process(self, *a, **k)
        if isinstance(event, dict):
            if request_seq is not None:
                event["request_seq"] = request_seq
            bus = getattr(self, "bus", None)
            if bus is not None:
                bus.emit(event)
        return event

    EventDispatcher.__init__ = _init
    EventDispatcher.process = _process
except NameError:
    pass
