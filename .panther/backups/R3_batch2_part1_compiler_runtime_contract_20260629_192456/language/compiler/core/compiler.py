from language.compiler.core.ir_builder import IRBuilder
from language.compiler.core.codegen import PythonCodeGenerator

class PantherCompiler:
    def compile_models(self, models, app_name="PantherApp"):
        ir = IRBuilder().build_program_from_models(models, name=app_name)
        return PythonCodeGenerator().generate(ir)
