from __future__ import annotations

from compiler.ast import BlockNode
from compiler.ast.base import SourceLocation as ASTSourceLocation
from compiler.lexer import Token, TokenKind

from .parse_error import ParseError
from .parser_base import ParserBase
from .parser_result import ParserResult


class BlockParser(ParserBase):
    """Recursive-descent parser stage for balanced PantherLang blocks.

    Part 3.2.4 owns block boundaries, balanced nested delimiters, nested brace
    recovery, and safe parser progress. It intentionally does not construct
    concrete statement nodes yet; Part 3.2.5 will replace statement skipping
    with real statement parsing.
    """

    def parse(self) -> ParserResult[BlockNode]:
        return self.parse_block_result()

    def parse_block_result(self) -> ParserResult[BlockNode]:
        try:
            return self.result(self.parse_block())
        except ParseError:
            self.recover_after_block_error()
            return self.result(None)

    def parse_block(self) -> BlockNode:
        left = self.consume(TokenKind.LEFT_BRACE, "Expected '{' to start block")
        while not self.check(TokenKind.RIGHT_BRACE) and not self.is_at_end():
            try:
                self.skip_statement_unit()
            except ParseError:
                self.recover_inside_block()
        if self.is_at_end():
            raise self.error("Unterminated block; expected '}' before end of file", expected=(TokenKind.RIGHT_BRACE,))
        self.consume(TokenKind.RIGHT_BRACE, "Expected '}' to close block")
        return BlockNode(location=self.ast_location(left), statements=())

    def skip_statement_unit(self) -> None:
        """Consume one block-level unit until statement parsing is introduced.

        Supported safely:
        - semicolon-terminated statements, e.g. print("x");
        - route/control-like units with nested { ... } bodies;
        - nested parentheses/brackets inside expressions and calls.
        """

        if self.check(TokenKind.LEFT_BRACE):
            self.parse_block()
            return
        consumed_any = False
        while not self.is_at_end() and not self.check(TokenKind.RIGHT_BRACE):
            if self.check(TokenKind.SEMICOLON):
                self.advance()
                return
            if self.check(TokenKind.LEFT_BRACE):
                self.parse_block()
                return
            if self.check(TokenKind.LEFT_PAREN):
                self.skip_balanced(TokenKind.LEFT_PAREN, TokenKind.RIGHT_PAREN)
                consumed_any = True
                continue
            if self.check(TokenKind.LEFT_BRACKET):
                self.skip_balanced(TokenKind.LEFT_BRACKET, TokenKind.RIGHT_BRACKET)
                consumed_any = True
                continue
            self.advance()
            consumed_any = True
        if not consumed_any and not self.check(TokenKind.RIGHT_BRACE):
            self.advance()

    def skip_balanced(self, open_kind: TokenKind, close_kind: TokenKind) -> None:
        self.consume(open_kind, f"Expected '{open_kind.value}'")
        depth = 1
        while depth > 0:
            if self.is_at_end():
                raise self.error(
                    f"Unterminated delimiter; expected '{close_kind.value}' before end of file",
                    expected=(close_kind,),
                )
            if self.check(open_kind):
                depth += 1
                self.advance()
                continue
            if self.check(close_kind):
                depth -= 1
                self.advance()
                continue
            if self.check(TokenKind.LEFT_BRACE):
                self.parse_block()
                continue
            self.advance()

    def recover_inside_block(self) -> None:
        while not self.is_at_end() and not self.check(TokenKind.SEMICOLON, TokenKind.RIGHT_BRACE):
            self.advance()
        if self.check(TokenKind.SEMICOLON):
            self.advance()

    def recover_after_block_error(self) -> None:
        while not self.is_at_end() and not self.check(TokenKind.RIGHT_BRACE):
            self.advance()
        if self.check(TokenKind.RIGHT_BRACE):
            self.advance()

    @staticmethod
    def ast_location(token: Token) -> ASTSourceLocation:
        return ASTSourceLocation(
            line=token.location.line,
            column=token.location.column,
            index=token.location.index,
        )


def parse_block(source: str, *, source_name: str = "<memory>") -> ParserResult[BlockNode]:
    return BlockParser.from_source(source, source_name=source_name).parse_block_result()
