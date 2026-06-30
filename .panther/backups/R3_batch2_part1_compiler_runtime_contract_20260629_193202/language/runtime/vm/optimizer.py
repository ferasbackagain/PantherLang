class PantherRuntimeOptimizer:
    def optimize(self, runtime_program):
        runtime_program = dict(runtime_program)
        runtime_program["optimized"] = True
        return runtime_program
