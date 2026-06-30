from pathlib import Path
from language.compiler.core.lexer import tokenize
from language.compiler.core.parser import parse


class PantherSourcePipeline:
    def read_source(self, path):
        return Path(path).read_text()

    def tokenize_source(self, source):
        return tokenize(source)

    def parse_source(self, source):
        return parse(source)

    def run_file(self, path):
        source = self.read_source(path)
        tokens = self.tokenize_source(source)
        parsed = self.parse_source(source)
        return {
            "path": str(path),
            "source_length": len(source),
            "token_count": len(tokens),
            "parsed": parsed,
        }
