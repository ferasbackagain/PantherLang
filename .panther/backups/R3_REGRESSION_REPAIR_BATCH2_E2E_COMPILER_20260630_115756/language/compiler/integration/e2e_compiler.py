from pathlib import Path
from language.compiler.ast.ast_builder import RealASTBuilder
from language.compiler.integration.semantic_integration import Phase2SemanticIntegration
from language.compiler.integration.ir_integration import Phase2IRIntegration
from language.compiler.core.codegen import PythonCodeGenerator


class PantherEndToEndCompiler:
    def compile_source(self, source):
        ast = RealASTBuilder().build(source)
        app_name = ast.app.name if ast.app else "PantherApp"

        semantic_ok, core_models = Phase2SemanticIntegration().analyze(ast)
        if not semantic_ok:
            raise ValueError("Semantic analysis failed")

        ir = Phase2IRIntegration().build_ir(core_models, app_name=app_name)
        code = PythonCodeGenerator().generate(ir)

        return {
            "ast": ast,
            "ir": ir,
            "code": code,
        }

    def compile_file(self, path):
        source = Path(path).read_text()
        return self.compile_source(source)
