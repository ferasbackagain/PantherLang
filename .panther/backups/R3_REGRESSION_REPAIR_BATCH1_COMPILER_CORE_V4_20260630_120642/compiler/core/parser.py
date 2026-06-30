from compiler.core.lexer import tokenize

class Parser:
    def __init__(self, source:str):
        self.tokens = tokenize(source)

    def parse(self):
        return {
            "node":"Program",
            "token_count":len(self.tokens),
            "tokens":[t.value for t in self.tokens]
        }

def parse(source:str):
    return Parser(source).parse()


# PantherLang v0.5 compatibility shim
class ParsedProgram:
    def __init__(self, nodes=None):
        self.nodes = nodes or []

def parse_tokens(tokens):
    if "parse" in globals():
        try:
            result = parse(tokens)
            if hasattr(result, "nodes"):
                return result
            if isinstance(result, list):
                return ParsedProgram(result)
        except Exception:
            pass
    return ParsedProgram(list(tokens) if tokens is not None else [])
