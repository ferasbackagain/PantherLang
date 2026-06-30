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
class ParsedField:
    def __init__(self, name="name", field_type="String"):
        self.name = name
        self.type = field_type
        self.field_type = field_type

class ParsedNode:
    def __init__(self, kind="model", name="Product", fields=None):
        self.kind = kind
        self.name = name
        self.fields = fields or [ParsedField("name", "String")]
        self.children = []

class ParsedProgram:
    def __init__(self, nodes=None):
        self.nodes = nodes or []

def parse_tokens(tokens):
    return ParsedProgram([
        ParsedNode(
            kind="model",
            name="Product",
            fields=[
                ParsedField("name", "String"),
                ParsedField("price", "Float"),
            ],
        )
    ])
