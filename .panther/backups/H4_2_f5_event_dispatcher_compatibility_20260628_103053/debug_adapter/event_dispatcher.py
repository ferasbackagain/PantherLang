from .event_merge import EventMergeEngine


class EventDispatcher:
    """Compatibility facade backed by the H4.2 F5 event merge engine."""

    def __init__(self, engine=None):
        self.engine = engine or EventMergeEngine()

    def event(self, name, body=None):
        return self.engine.event(name, body or {})

    def initialized(self):
        return self.engine.initialized()

    def process(self, name="PantherLang Program", system_process_id=0, start_method="launch"):
        return self.engine.process(
            name=name,
            system_process_id=system_process_id,
            start_method=start_method,
        )

    def continued(self, thread_id=1, all_threads_continued=True):
        return self.engine.continued(
            thread_id=thread_id,
            all_threads_continued=all_threads_continued,
        )

    def stopped(self, reason="pause", thread_id=1, all_threads_stopped=True):
        return self.engine.stopped(
            reason=reason,
            thread_id=thread_id,
            all_threads_stopped=all_threads_stopped,
        )

    def terminated(self, restart=False):
        return self.engine.terminated(restart=restart)

    def exited(self, exit_code=0):
        return self.engine.exited(exit_code=exit_code)

    def output(self, output, category="console"):
        return self.engine.output(output=output, category=category)
