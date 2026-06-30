from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class TokenKind(str, Enum):
    EOF = "EOF"
    UNKNOWN = "UNKNOWN"
    IDENTIFIER = "IDENTIFIER"
    NUMBER = "NUMBER"
    STRING = "STRING"
    PANTHER = "PANTHER"
    MAIN = "MAIN"
    WEB = "WEB"
    API = "API"
    AI = "AI"
    TEST = "TEST"
    PRINT = "PRINT"
    RETURN = "RETURN"
    ROUTE = "ROUTE"
    GET = "GET"
    POST = "POST"
    TRUE = "TRUE"
    FALSE = "FALSE"
    ASSERT = "ASSERT"
    PROMPT = "PROMPT"
    LEFT_BRACE = "LEFT_BRACE"
    RIGHT_BRACE = "RIGHT_BRACE"
    LEFT_PAREN = "LEFT_PAREN"
    RIGHT_PAREN = "RIGHT_PAREN"
    LEFT_BRACKET = "LEFT_BRACKET"
    RIGHT_BRACKET = "RIGHT_BRACKET"
    COMMA = "COMMA"
    COLON = "COLON"
    SEMICOLON = "SEMICOLON"
    DOT = "DOT"
    EQUAL = "EQUAL"
    PLUS = "PLUS"
    MINUS = "MINUS"
    STAR = "STAR"
    SLASH = "SLASH"
    BANG = "BANG"
    EQUAL_EQUAL = "EQUAL_EQUAL"
    BANG_EQUAL = "BANG_EQUAL"
    GREATER = "GREATER"
    GREATER_EQUAL = "GREATER_EQUAL"
    LESS = "LESS"
    LESS_EQUAL = "LESS_EQUAL"
    ARROW = "ARROW"


KEYWORDS = {
    "panther": TokenKind.PANTHER,
    "main": TokenKind.MAIN,
    "web": TokenKind.WEB,
    "api": TokenKind.API,
    "ai": TokenKind.AI,
    "test": TokenKind.TEST,
    "print": TokenKind.PRINT,
    "return": TokenKind.RETURN,
    "route": TokenKind.ROUTE,
    "get": TokenKind.GET,
    "post": TokenKind.POST,
    "true": TokenKind.TRUE,
    "false": TokenKind.FALSE,
    "assert": TokenKind.ASSERT,
    "prompt": TokenKind.PROMPT,
}


@dataclass(frozen=True)
class SourceLocation:
    line: int
    column: int
    index: int


@dataclass(frozen=True)
class Token:
    kind: TokenKind
    lexeme: str
    literal: object | None
    location: SourceLocation


class LexerError(Exception):
    def __init__(self, message: str, location: SourceLocation):
        super().__init__(f"{message} at line {location.line}, column {location.column}")
        self.message = message
        self.location = location
