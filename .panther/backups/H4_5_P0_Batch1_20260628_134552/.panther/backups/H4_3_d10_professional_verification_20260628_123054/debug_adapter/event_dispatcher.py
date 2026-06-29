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
