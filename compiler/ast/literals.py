from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Any

from compiler.ast.expressions import BooleanLiteral, Expression, NullLiteral, NumberLiteral, StringLiteral
from compiler.ast.base import SourceLocation
from compiler.lexer import Token, TokenKind


class LiteralKind(str, Enum):
    INTEGER = "integer"
    FLOAT = "float"
    STRING = "string"
    BOOLEAN = "boolean"
    NULL = "null"


@dataclass(frozen=True)
class LiteralParseResult:
    kind: LiteralKind
    value: Any
    expression: Expression


def token_source_location(token: Token) -> SourceLocation:
    return SourceLocation(
        line=token.location.line,
        column=token.location.column,
        index=token.location.index,
    )


def parse_number_literal(value: object, lexeme: str) -> tuple[LiteralKind, int | float]:
    if isinstance(value, bool):
        raise ValueError("Boolean cannot be parsed as a numeric literal")
    if isinstance(value, int):
        return LiteralKind.INTEGER, value
    if isinstance(value, float):
        return LiteralKind.FLOAT, value

    text = str(value if value is not None else lexeme).strip()
    if not text:
        raise ValueError("Empty numeric literal")
    if any(ch in text for ch in (".", "e", "E")):
        return LiteralKind.FLOAT, float(text)
    return LiteralKind.INTEGER, int(text)


def parse_literal_token(token: Token) -> LiteralParseResult | None:
    location = token_source_location(token)

    if token.kind == TokenKind.NUMBER:
        kind, value = parse_number_literal(token.literal, token.lexeme)
        return LiteralParseResult(kind=kind, value=value, expression=NumberLiteral(location=location, value=value))

    if token.kind == TokenKind.STRING:
        value = token.literal if token.literal is not None else token.lexeme.strip('"')
        return LiteralParseResult(
            kind=LiteralKind.STRING,
            value=str(value),
            expression=StringLiteral(location=location, value=str(value)),
        )

    if token.kind == TokenKind.TRUE:
        return LiteralParseResult(kind=LiteralKind.BOOLEAN, value=True, expression=BooleanLiteral(location=location, value=True))

    if token.kind == TokenKind.FALSE:
        return LiteralParseResult(kind=LiteralKind.BOOLEAN, value=False, expression=BooleanLiteral(location=location, value=False))

    if token.kind == getattr(TokenKind, "NULL", None) or token.lexeme in {"null", "none"}:
        return LiteralParseResult(kind=LiteralKind.NULL, value=None, expression=NullLiteral(location=location))

    return None


def is_literal_token(token: Token) -> bool:
    return parse_literal_token(token) is not None
