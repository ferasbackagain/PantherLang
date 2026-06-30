class ExecutionMergeEngine:
    def __init__(self):
        self.state = "created"
        self.execution = {}

    def current(self):
        return {"state": self.state, "execution": dict(self.execution)}

    def configuration_done(self):
        self.state = "configured"
        self.execution["configured"] = True
        return self.current()

    def launch(self, program, dry_run=False):
        self.state = "running"
        self.execution.update({"program": program, "dryRun": dry_run, "running": True})
        return self.current()

    def pause(self):
        self.state = "paused"
        self.execution.update({"paused": True, "running": False})
        return self.current()

    def continue_execution(self):
        self.state = "running"
        self.execution.update({"paused": False, "running": True})
        return self.current()

    def stop(self):
        self.state = "stopped"
        self.execution.update({"stopped": True, "running": False})
        return self.current()

    def terminate(self):
        self.state = "terminated"
        self.execution.update({"terminated": True, "running": False})
        return self.current()

    def set_breakpoints(self, breakpoints):
        self.execution["breakpoints"] = list(breakpoints)
        return self.current()

    def assert_execution_contract(self, item):
        return isinstance(item, dict) and "state" in item and "execution" in item
