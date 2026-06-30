from .execution_merge import ExecutionMergeEngine
class ExecutionDispatcher:
    def __init__(self, events=None): self.events=events; self.engine=ExecutionMergeEngine()
    def configuration_done(self): return self.engine.configuration_done()
    def set_breakpoints(self, breakpoints): return self.engine.set_breakpoints(breakpoints)
    def launch(self, program, dry_run=False): return self.engine.launch(program, dry_run=dry_run)
    def pause(self): return self.engine.pause()
    def continue_execution(self): return self.engine.continue_execution()
    def stop(self): return self.engine.stop()
    def terminate(self): return self.engine.terminate()
