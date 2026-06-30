from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from compiler.lexer import SourceLocation, Token, TokenKind


@dataclass(frozen=True)
class ParseDiagnostic:
    """Structured parser diagnostic used by TokenStream and parser stages."""

    message: str
    location: SourceLocation
    token_kind: TokenKind | None = None
    token_lexeme: str = ""
    expected: tuple[TokenKind | str, ...] = ()

    def to_dict(self) -> dict[str, object]:
        return {
            "message": self.message,
            "location": {
                "line": self.location.line,
                "column": self.location.column,
                "index": self.location.index,
            },
            "token_kind": self.token_kind.value if self.token_kind is not None else None,
            "token_lexeme": self.token_lexeme,
            "expected": [item.value if isinstance(item, TokenKind) else str(item) for item in self.expected],
        }


class ParseError(SyntaxError):
    """Parser exception with source-aware diagnostic payload."""

    def __init__(
        self,
        message: str,
        token: Token | None = None,
        expected: Iterable[TokenKind | str] = (),
        location: SourceLocation | None = None,
    ) -> None:
        if token is None and location is None:
            location = SourceLocation(line=1, column=1, index=0)
        final_location = token.location if token is not None else location
        assert final_location is not None
        expected_tuple = tuple(expected)
        self.token = token
        self.diagnostic = ParseDiagnostic(
            message=message,
            location=final_location,
            token_kind=token.kind if token is not None else None,
            token_lexeme=token.lexeme if token is not None else "",
            expected=expected_tuple,
        )
        suffix = f" at line {final_location.line}, column {final_location.column}"
        if expected_tuple:
            names = ", ".join(item.value if isinstance(item, TokenKind) else str(item) for item in expected_tuple)
            suffix += f"; expected {names}"
        super().__init__(message + suffix)

    def to_dict(self) -> dict[str, object]:
        return self.diagnostic.to_dict()
