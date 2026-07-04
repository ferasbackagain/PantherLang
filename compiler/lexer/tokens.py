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
    LET = "LET"
    IF = "IF"
    ELIF = "ELIF"
    ELSE = "ELSE"
    WHILE = "WHILE"
    FOR = "FOR"
    LOOP = "LOOP"
    BREAK = "BREAK"
    CONTINUE = "CONTINUE"
    FN = "FN"
    STRUCT = "STRUCT"
    ENUM = "ENUM"
    TRAIT = "TRAIT"
    IMPORT = "IMPORT"
    MATCH = "MATCH"
    NULL = "NULL"
    IN = "IN"
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
    DOT_DOT = "DOT_DOT"
    EQUAL = "EQUAL"
    PLUS = "PLUS"
    MINUS = "MINUS"
    STAR = "STAR"
    SLASH = "SLASH"
    PERCENT = "PERCENT"
    BANG = "BANG"
    EQUAL_EQUAL = "EQUAL_EQUAL"
    BANG_EQUAL = "BANG_EQUAL"
    GREATER = "GREATER"
    GREATER_EQUAL = "GREATER_EQUAL"
    LESS = "LESS"
    LESS_EQUAL = "LESS_EQUAL"
    ARROW = "ARROW"
    STAR_STAR = "STAR_STAR"
    PIPE_PIPE = "PIPE_PIPE"
    AMP_AMP = "AMP_AMP"
    PLUS_EQUAL = "PLUS_EQUAL"
    MINUS_EQUAL = "MINUS_EQUAL"
    STAR_EQUAL = "STAR_EQUAL"
    SLASH_EQUAL = "SLASH_EQUAL"
    PERCENT_EQUAL = "PERCENT_EQUAL"
    AMPERSAND = "AMPERSAND"
    PIPE = "PIPE"


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
    "let": TokenKind.LET,
    "if": TokenKind.IF,
    "elif": TokenKind.ELIF,
    "else": TokenKind.ELSE,
    "while": TokenKind.WHILE,
    "for": TokenKind.FOR,
    "loop": TokenKind.LOOP,
    "break": TokenKind.BREAK,
    "continue": TokenKind.CONTINUE,
    "fn": TokenKind.FN,
    "struct": TokenKind.STRUCT,
    "enum": TokenKind.ENUM,
    "trait": TokenKind.TRAIT,
    "import": TokenKind.IMPORT,
    "match": TokenKind.MATCH,
    "null": TokenKind.NULL,
    "in": TokenKind.IN,
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
