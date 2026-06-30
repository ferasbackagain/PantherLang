from language.compiler.core.ir_builder import IRBuilder


class Phase2IRIntegration:
    def build_ir(self, core_models, app_name="PantherApp"):
        return IRBuilder().build_program_from_models(core_models, name=app_name)
