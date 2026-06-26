from language.compiler.ast import ASTProgram
from language.compiler.parsers import AppParser, ModelParser, ApiParser, PageParser, AgentParser


class RealASTBuilder:
    def build(self, source):
        return ASTProgram(
            app=AppParser().parse(source),
            models=ModelParser().parse(source),
            apis=ApiParser().parse(source),
            pages=PageParser().parse(source),
            agents=AgentParser().parse(source),
        )
