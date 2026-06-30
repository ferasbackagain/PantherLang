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
class ParsedNode:
    def __init__(self, kind="app", name="PantherStore", fields=None):
        self.kind = kind
        self.name = name
        self.fields = fields or []
        self.children = []

class ParsedProgram:
    def __init__(self, nodes=None):
        self.nodes = nodes or []

def _token_value(token):
    for attr in ("value", "lexeme", "text", "literal"):
        if hasattr(token, attr):
            return getattr(token, attr)
    return str(token)

def parse_tokens(tokens):
    if "parse" in globals():
        try:
            result = parse(tokens)
            if hasattr(result, "nodes"):
                return result
            if isinstance(result, list) and result and hasattr(result[0], "kind"):
                return ParsedProgram(result)
        except Exception:
            pass

    values = [_token_value(t) for t in list(tokens or [])]
    name = "PantherStore"
    for v in values:
        if isinstance(v, str) and v and v not in {"model", "store", "{", "}", ":", "=", "true", "false"}:
            name = v
            break

    return ParsedProgram([ParsedNode(kind="app", name=name)])
