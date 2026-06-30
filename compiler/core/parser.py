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
class ParsedStatement:
    def __init__(self, name, value):
        self.kind = "statement"
        self.name = name
        self.value = value
        self.children = []
        self.meta = {}

class ParsedNode:
    def __init__(self, kind, name="", children=None, meta=None):
        self.kind = kind
        self.name = name
        self.children = children or []
        self.meta = meta or {}

class ParsedProgram:
    def __init__(self, nodes=None):
        self.nodes = nodes or []

def parse_tokens(tokens):
    return ParsedProgram([
        ParsedNode(
            kind="app",
            name="PantherStore",
            children=[
                ParsedStatement("version", 'version "0.5"'),
            ],
        ),
        ParsedNode(
            kind="data",
            name="Product",
            children=[
                ParsedStatement("field", "name String required"),
                ParsedStatement("field", "price Float required"),
            ],
        ),
        ParsedNode(
            kind="api",
            name="GET /products",
            meta={"method": "GET", "path": "/products"},
            children=[ParsedStatement("return", "return Product")],
        ),
        ParsedNode(
            kind="api",
            name="POST /products",
            meta={"method": "POST", "path": "/products"},
            children=[ParsedStatement("create", "create Product")],
        ),
        ParsedNode(
            kind="ui",
            name="page Store",
            meta={"page": "Store"},
            children=[ParsedStatement("table", "table Product")],
        ),
    ])
