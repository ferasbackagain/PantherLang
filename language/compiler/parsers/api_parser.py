from language.compiler.ast import ASTApi
from .block_utils import extract_api


class ApiParser:
    def parse(self, source):
        return [ASTApi(method=method, path=path) for method, path, body in extract_api(source)]
