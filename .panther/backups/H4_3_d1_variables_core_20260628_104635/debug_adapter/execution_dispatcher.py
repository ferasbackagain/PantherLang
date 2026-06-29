from .execution_merge import ExecutionMergeEngine


class ExecutionDispatcher:
    """Compatibility facade backed by the H4.2 F6 execution merge engine."""

    def __init__(self, engine=None):
        self.engine = engine or ExecutionMergeEngine()

    def configuration_done(self):
        return self.engine.configuration_done()

    def set_breakpoints(self, breakpoints):
        return self.engine.set_breakpoints(breakpoints)

    def launch(self, program=None, dry_run=False):
        return self.engine.launch(program=program, dry_run=dry_run)

    def continue_execution(self):
        return self.engine.continue_execution()

    def pause(self):
        return self.engine.pause()

    def stop(self):
        return self.engine.stop()

    def terminate(self):
        return self.engine.terminate()

    def disconnect(self):
        return self.engine.disconnect()

    def current(self):
        return self.engine.current()
