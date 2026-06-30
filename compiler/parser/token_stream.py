from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator, Sequence

from compiler.lexer import Token, TokenKind, lex_source

from .cursor import TokenCursor
from .parse_error import ParseError


class TokenStream:
    """Parser-facing token navigation layer over lexer output.

    The stream is intentionally small and strict: it guarantees an EOF token,
    clamps lookahead safely, and exposes checkpoint/rollback so recursive descent
    parser stages can speculate without corrupting state.
    """

    def __init__(self, tokens: Sequence[Token], *, source_name: str = "<memory>") -> None:
        if not tokens:
            raise ValueError("TokenStream requires at least an EOF token")
        self.tokens: tuple[Token, ...] = tuple(tokens)
        if self.tokens[-1].kind is not TokenKind.EOF:
            raise ValueError("TokenStream must end with TokenKind.EOF")
        self.cursor = TokenCursor(0)
        self.source_name = source_name

    @classmethod
    def from_source(cls, source: str, *, source_name: str = "<memory>") -> "TokenStream":
        return cls(lex_source(source), source_name=source_name)

    @property
    def position(self) -> int:
        return self.cursor.position

    @property
    def current(self) -> Token:
        return self.peek(0)

    @property
    def previous(self) -> Token:
        index = max(0, min(self.position - 1, len(self.tokens) - 1))
        return self.tokens[index]

    def __len__(self) -> int:
        return len(self.tokens)

    def __iter__(self) -> Iterator[Token]:
        return iter(self.tokens)

    def is_at_end(self) -> bool:
        return self.current.kind is TokenKind.EOF

    def peek(self, offset: int = 0) -> Token:
        if offset < 0:
            raise ValueError("TokenStream.peek offset cannot be negative")
        index = min(self.position + offset, len(self.tokens) - 1)
        return self.tokens[index]

    def check(self, *kinds: TokenKind) -> bool:
        return bool(kinds) and self.current.kind in kinds

    def check_next(self, *kinds: TokenKind) -> bool:
        return bool(kinds) and self.peek(1).kind in kinds

    def advance(self) -> Token:
        token = self.current
        if not self.is_at_end():
            self.cursor.advance()
        return token

    def match(self, *kinds: TokenKind) -> Token | None:
        if self.check(*kinds):
            return self.advance()
        return None

    def consume(self, kind: TokenKind, message: str | None = None) -> Token:
        if self.check(kind):
            return self.advance()
        found = self.current
        msg = message or f"Expected {kind.value}, found {found.kind.value}"
        raise ParseError(msg, token=found, expected=(kind,))

    def consume_any(self, kinds: Sequence[TokenKind], message: str | None = None) -> Token:
        if not kinds:
            raise ValueError("consume_any requires at least one TokenKind")
        if self.check(*kinds):
            return self.advance()
        found = self.current
        expected = tuple(kinds)
        msg = message or "Expected one of " + ", ".join(kind.value for kind in expected)
        raise ParseError(msg, token=found, expected=expected)

    def checkpoint(self) -> int:
        return self.cursor.save()

    def rollback(self, checkpoint: int) -> None:
        if checkpoint >= len(self.tokens):
            checkpoint = len(self.tokens) - 1
        self.cursor.restore(checkpoint)

    @contextmanager
    def speculative(self) -> Iterator["TokenStream"]:
        checkpoint = self.checkpoint()
        try:
            yield self
        except Exception:
            self.rollback(checkpoint)
            raise

    def slice_kinds(self, start: int = 0, end: int | None = None) -> tuple[TokenKind, ...]:
        return tuple(token.kind for token in self.tokens[start:end])

    def remaining_kinds(self) -> tuple[TokenKind, ...]:
        return self.slice_kinds(self.position)
