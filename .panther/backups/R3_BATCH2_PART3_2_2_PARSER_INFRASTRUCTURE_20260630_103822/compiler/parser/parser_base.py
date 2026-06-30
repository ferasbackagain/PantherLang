from __future__ import annotations

from compiler.lexer import Token, TokenKind

from .parse_error import ParseError
from .token_stream import TokenStream


class ParserBase:
    """Shared recursive-descent parser utilities for upcoming parser segments."""

    def __init__(self, stream: TokenStream):
        self.stream = stream
        self.errors: list[ParseError] = []

    @classmethod
    def from_source(cls, source: str, *, source_name: str = "<memory>"):
        return cls(TokenStream.from_source(source, source_name=source_name))

    @property
    def current(self) -> Token:
        return self.stream.current

    @property
    def previous(self) -> Token:
        return self.stream.previous

    def is_at_end(self) -> bool:
        return self.stream.is_at_end()

    def peek(self, offset: int = 0) -> Token:
        return self.stream.peek(offset)

    def check(self, *kinds: TokenKind) -> bool:
        return self.stream.check(*kinds)

    def check_next(self, *kinds: TokenKind) -> bool:
        return self.stream.check_next(*kinds)

    def advance(self) -> Token:
        return self.stream.advance()

    def match(self, *kinds: TokenKind) -> Token | None:
        return self.stream.match(*kinds)

    def consume(self, kind: TokenKind, message: str | None = None) -> Token:
        return self.stream.consume(kind, message)

    def consume_any(self, kinds: tuple[TokenKind, ...] | list[TokenKind], message: str | None = None) -> Token:
        return self.stream.consume_any(kinds, message)

    def error(self, message: str, token: Token | None = None, expected: tuple[TokenKind | str, ...] = ()) -> ParseError:
        err = ParseError(message, token=token or self.current, expected=expected)
        self.errors.append(err)
        return err

    def synchronize(self) -> None:
        """Move to a likely statement boundary after a parser error."""
        if not self.is_at_end():
            self.advance()
        boundaries = {
            TokenKind.PANTHER,
            TokenKind.MAIN,
            TokenKind.PRINT,
            TokenKind.RETURN,
            TokenKind.ROUTE,
            TokenKind.GET,
            TokenKind.POST,
            TokenKind.TEST,
        }
        while not self.is_at_end():
            if self.previous.kind is TokenKind.SEMICOLON:
                return
            if self.current.kind in boundaries:
                return
            self.advance()
