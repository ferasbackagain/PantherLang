from __future__ import annotations

from typing import Callable, TypeVar

from compiler.lexer import Token, TokenKind

from .diagnostics import DiagnosticBag, ParserDiagnostic
from .parse_error import ParseError
from .parser_context import ParserContext
from .parser_result import ParserResult
from .token_stream import TokenStream

T = TypeVar("T")


class ParserBase:
    """Shared recursive-descent parser infrastructure.

    This layer owns parser state, diagnostics, recovery, optional parsing,
    speculation, and consistent ParserResult construction. Concrete parser
    stages should subclass this class instead of touching TokenStream directly.
    """

    def __init__(self, stream: TokenStream | ParserContext):
        if isinstance(stream, ParserContext):
            self.context = stream
        else:
            self.context = ParserContext(stream)
        self.stream = self.context.stream
        self.errors: list[ParseError] = []

    @classmethod
    def from_source(cls, source: str, *, source_name: str = "<memory>"):
        return cls(TokenStream.from_source(source, source_name=source_name))

    @property
    def diagnostics(self) -> DiagnosticBag:
        return self.context.diagnostics

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
        try:
            return self.stream.consume(kind, message)
        except ParseError as err:
            self.errors.append(err)
            self.diagnostics.error(err.diagnostic.message, err.token or self.current, expected=(kind,))
            raise

    def consume_any(self, kinds: tuple[TokenKind, ...] | list[TokenKind], message: str | None = None) -> Token:
        try:
            return self.stream.consume_any(kinds, message)
        except ParseError as err:
            self.errors.append(err)
            self.diagnostics.error(err.diagnostic.message, err.token or self.current, expected=tuple(kinds))
            raise

    def optional(self, parser: Callable[[], T]) -> T | None:
        """Try parser callable and rollback cleanly on ParseError."""
        checkpoint = self.stream.checkpoint()
        before_diag_count = len(self.diagnostics.diagnostics)
        before_error_count = len(self.errors)
        try:
            return parser()
        except ParseError:
            self.stream.rollback(checkpoint)
            del self.diagnostics.diagnostics[before_diag_count:]
            del self.errors[before_error_count:]
            return None

    def expect(self, kind: TokenKind, message: str | None = None) -> Token | None:
        """Non-throwing consume used by recovery-aware parser stages."""
        if self.check(kind):
            return self.advance()
        self.diagnostic(message or f"Expected {kind.value}", expected=(kind,))
        return None

    def diagnostic(
        self,
        message: str,
        *,
        token: Token | None = None,
        expected: tuple[TokenKind | str, ...] = (),
        code: str = "PARSER_ERROR",
    ) -> ParserDiagnostic:
        return self.diagnostics.error(message, token or self.current, expected=expected, code=code)

    def error(self, message: str, token: Token | None = None, expected: tuple[TokenKind | str, ...] = ()) -> ParseError:
        err = ParseError(message, token=token or self.current, expected=expected)
        self.errors.append(err)
        self.diagnostic(message, token=token or self.current, expected=expected)
        return err

    def recover_to(self, *kinds: TokenKind) -> None:
        self.context.recover_to(*kinds)

    def synchronize(self) -> None:
        """Move to a likely statement boundary after a parser error."""
        if not self.is_at_end():
            self.advance()
        self.recover_to()

    def result(self, node: T | None) -> ParserResult[T]:
        return ParserResult(node=node, diagnostics=tuple(self.diagnostics.diagnostics))
