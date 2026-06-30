from dataclasses import dataclass


@dataclass(frozen=True)
class Token:
    type: str
    value: str
    line: int
    column: int

    def __repr__(self):
        return f"{self.type}({self.value!r})@{self.line}:{self.column}"


class TokenType:
    KEYWORD = "KEYWORD"
    IDENTIFIER = "IDENTIFIER"
    STRING = "STRING"
    NUMBER = "NUMBER"
    SYMBOL = "SYMBOL"
    EOF = "EOF"
