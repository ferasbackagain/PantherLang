from language.compiler.integration import PantherEndToEndCompiler
from language.runtime.vm.execution_engine import RuntimeExecutionEngine
from language.runtime.vm.optimizer import PantherRuntimeOptimizer


class PantherRuntimePipeline:
    def compile_to_runtime_program(self, source):
        compiled = PantherEndToEndCompiler().compile_source(source)
        ir_data = compiled["ir"].to_dict()

        models = {}
        for model in ir_data.get("models", []):
            models[model["name"]] = [field["name"] for field in model.get("fields", [])]

        return {
            "app": ir_data.get("name", "PantherApp"),
            "models": models,
            "ir": ir_data,
        }

    def execute_source(self, source):
        runtime_program = self.compile_to_runtime_program(source)
        runtime_program = PantherRuntimeOptimizer().optimize(runtime_program)

        engine = RuntimeExecutionEngine()
        engine.load(runtime_program)
        return engine.execute()
