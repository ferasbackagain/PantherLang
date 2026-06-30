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
