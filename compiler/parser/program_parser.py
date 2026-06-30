from __future__ import annotations

from dataclasses import dataclass
from typing import Callable

from compiler.ast import (
    AiBlockNode,
    ApiBlockNode,
    BlockNode,
    MainBlockNode,
    ProgramNode,
    TestBlockNode,
    WebBlockNode,
)
from compiler.ast.base import SourceLocation as ASTSourceLocation
from compiler.lexer import Token, TokenKind

from .block_parser import BlockParser
from .parse_error import ParseError
from .parser_base import ParserBase
from .parser_result import ParserResult


@dataclass(frozen=True)
class TopLevelBlockSpec:
    keyword: TokenKind
    node_factory: Callable[..., object]
    requires_panther_prefix: bool = False
    allows_name: bool = False


class ProgramParser(ParserBase):
    """Recursive-descent parser stage for PantherLang top-level program shape.

    Part 3.2.3 intentionally parses only the program envelope and top-level
    block declarations. Block contents are consumed with balanced-brace
    skipping until Part 3.2.4 introduces the real Block Parser.
    """

    TOP_LEVEL_STARTS = (TokenKind.PANTHER, TokenKind.WEB, TokenKind.API, TokenKind.AI, TokenKind.TEST)

    def parse(self) -> ParserResult[ProgramNode]:
        return self.parse_program()

    def parse_program(self) -> ParserResult[ProgramNode]:
        body = []
        while not self.is_at_end():
            try:
                body.append(self.parse_top_level_block())
            except ParseError:
                self.synchronize_top_level()
        self.expect(TokenKind.EOF, "Expected end of file after program")
        return self.result(ProgramNode(location=self.ast_location(self.previous), body=tuple(body)))

    def parse_top_level_block(self):
        if self.check(TokenKind.PANTHER):
            return self.parse_panther_main_block()
        if self.check(TokenKind.WEB):
            return self.parse_named_body_block(TokenKind.WEB, WebBlockNode, "web")
        if self.check(TokenKind.API):
            return self.parse_named_body_block(TokenKind.API, ApiBlockNode, "api")
        if self.check(TokenKind.AI):
            return self.parse_named_body_block(TokenKind.AI, AiBlockNode, "ai")
        if self.check(TokenKind.TEST):
            return self.parse_test_block()
        token = self.current
        raise self.error(
            "Expected top-level PantherLang block",
            token=token,
            expected=self.TOP_LEVEL_STARTS,
        )

    def parse_panther_main_block(self) -> MainBlockNode:
        start = self.consume(TokenKind.PANTHER, "Expected 'panther' at program entry")
        self.consume(TokenKind.MAIN, "Expected 'main' after 'panther'")
        body = self.parse_placeholder_block()
        return MainBlockNode(location=self.ast_location(start), body=body)

    def parse_named_body_block(self, keyword: TokenKind, factory, label: str):
        start = self.consume(keyword, f"Expected '{label}' block")
        body = self.parse_placeholder_block()
        return factory(location=self.ast_location(start), body=body)

    def parse_test_block(self) -> TestBlockNode:
        start = self.consume(TokenKind.TEST, "Expected 'test' block")
        name = ""
        if self.check(TokenKind.STRING, TokenKind.IDENTIFIER):
            token = self.advance()
            name = str(token.literal if token.literal is not None else token.lexeme)
        body = self.parse_placeholder_block()
        return TestBlockNode(location=self.ast_location(start), name=name, body=body)

    def parse_placeholder_block(self) -> BlockNode:
        """Parse a balanced block through the dedicated BlockParser stage.

        Statement construction remains intentionally deferred to Part 3.2.5,
        but block ownership now lives in `BlockParser` instead of ad-hoc
        top-level placeholder scanning.
        """

        return BlockParser(self.context).parse_block()

    def synchronize_top_level(self) -> None:
        while not self.is_at_end() and not self.check(*self.TOP_LEVEL_STARTS):
            self.advance()

    @staticmethod
    def ast_location(token: Token) -> ASTSourceLocation:
        return ASTSourceLocation(
            line=token.location.line,
            column=token.location.column,
            index=token.location.index,
        )


def parse_program(source: str, *, source_name: str = "<memory>") -> ParserResult[ProgramNode]:
    return ProgramParser.from_source(source, source_name=source_name).parse_program()
