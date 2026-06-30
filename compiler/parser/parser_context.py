from __future__ import annotations

from contextlib import contextmanager
from dataclasses import dataclass, field
from typing import Iterator

from compiler.lexer import TokenKind

from .diagnostics import DiagnosticBag
from .token_stream import TokenStream


@dataclass
class ParserContext:
    """Shared mutable parser context for recursive descent stages."""

    stream: TokenStream
    diagnostics: DiagnosticBag = field(default_factory=DiagnosticBag)
    panic_mode: bool = False

    def checkpoint(self) -> int:
        return self.stream.checkpoint()

    def rollback(self, checkpoint: int) -> None:
        self.stream.rollback(checkpoint)

    @contextmanager
    def speculative(self) -> Iterator[None]:
        """Rollback automatically unless the caller commits by exhausting normally with commit()."""
        checkpoint = self.checkpoint()
        marker = {"commit": False}

        def commit() -> None:
            marker["commit"] = True

        self.commit = commit  # type: ignore[attr-defined]
        try:
            yield
        finally:
            if not marker["commit"]:
                self.rollback(checkpoint)
            if hasattr(self, "commit"):
                delattr(self, "commit")

    def recover_to(self, *kinds: TokenKind) -> None:
        """Advance until a recovery boundary or EOF is reached."""
        self.panic_mode = True
        boundaries = set(kinds) or {
            TokenKind.SEMICOLON,
            TokenKind.RIGHT_BRACE,
            TokenKind.PANTHER,
            TokenKind.MAIN,
            TokenKind.PRINT,
            TokenKind.RETURN,
            TokenKind.ROUTE,
            TokenKind.GET,
            TokenKind.POST,
            TokenKind.TEST,
        }
        while not self.stream.is_at_end() and self.stream.current.kind not in boundaries:
            self.stream.advance()
        self.panic_mode = False
