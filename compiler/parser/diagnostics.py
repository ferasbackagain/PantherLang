from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Iterable

from compiler.lexer import SourceLocation, Token, TokenKind


class DiagnosticSeverity(str, Enum):
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"


@dataclass(frozen=True)
class ParserDiagnostic:
    """Stable diagnostic record emitted by parser infrastructure."""

    message: str
    location: SourceLocation
    severity: DiagnosticSeverity = DiagnosticSeverity.ERROR
    token_kind: TokenKind | None = None
    token_lexeme: str = ""
    expected: tuple[TokenKind | str, ...] = ()
    code: str = "PARSER_ERROR"

    @classmethod
    def from_token(
        cls,
        message: str,
        token: Token,
        *,
        expected: Iterable[TokenKind | str] = (),
        severity: DiagnosticSeverity = DiagnosticSeverity.ERROR,
        code: str = "PARSER_ERROR",
    ) -> "ParserDiagnostic":
        return cls(
            message=message,
            location=token.location,
            severity=severity,
            token_kind=token.kind,
            token_lexeme=token.lexeme,
            expected=tuple(expected),
            code=code,
        )

    def to_dict(self) -> dict[str, object]:
        return {
            "code": self.code,
            "severity": self.severity.value,
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


@dataclass
class DiagnosticBag:
    """Collects parser diagnostics while keeping error policy centralized."""

    diagnostics: list[ParserDiagnostic] = field(default_factory=list)

    def add(self, diagnostic: ParserDiagnostic) -> ParserDiagnostic:
        self.diagnostics.append(diagnostic)
        return diagnostic

    def error(self, message: str, token: Token, *, expected: Iterable[TokenKind | str] = (), code: str = "PARSER_ERROR") -> ParserDiagnostic:
        return self.add(ParserDiagnostic.from_token(message, token, expected=expected, code=code))

    def warning(self, message: str, token: Token, *, code: str = "PARSER_WARNING") -> ParserDiagnostic:
        return self.add(ParserDiagnostic.from_token(message, token, severity=DiagnosticSeverity.WARNING, code=code))

    @property
    def has_errors(self) -> bool:
        return any(item.severity is DiagnosticSeverity.ERROR for item in self.diagnostics)

    def clear(self) -> None:
        self.diagnostics.clear()

    def to_list(self) -> list[dict[str, object]]:
        return [item.to_dict() for item in self.diagnostics]
