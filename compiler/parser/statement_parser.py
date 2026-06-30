from __future__ import annotations

from compiler.ast import (
    AssignmentStatement,
    BlockNode,
    BooleanLiteral,
    Expression,
    ExpressionStatement,
    IdentifierExpression,
    NumberLiteral,
    PrintStatement,
    ReturnStatement,
    RouteStatement,
    StringLiteral,
)
from compiler.ast.base import SourceLocation as ASTSourceLocation
from compiler.lexer import Token, TokenKind

from .parse_error import ParseError
from .parser_base import ParserBase


class StatementParser(ParserBase):
    """Parser stage for concrete block-level statements.

    Part 3.2.5 intentionally implements a conservative statement layer while
    the full Pratt/recursive expression parser is reserved for Part 3.3. The
    statement parser now constructs real statement AST nodes for the PantherLang
    core syntax that earlier block parsing only skipped.
    """

    STATEMENT_STARTS = (
        TokenKind.PRINT,
        TokenKind.RETURN,
        TokenKind.ROUTE,
        TokenKind.IDENTIFIER,
        TokenKind.LEFT_BRACE,
    )

    def parse_statement(self):
        if self.check(TokenKind.PRINT):
            return self.parse_print_statement()
        if self.check(TokenKind.RETURN):
            return self.parse_return_statement()
        if self.check(TokenKind.ROUTE):
            return self.parse_route_statement()
        if self.check(TokenKind.LEFT_BRACE):
            return self.parse_nested_block()
        return self.parse_expression_or_assignment_statement()

    def parse_print_statement(self) -> PrintStatement:
        start = self.consume(TokenKind.PRINT, "Expected 'print'")
        expression = None
        if self.match(TokenKind.LEFT_PAREN):
            expression = self.parse_expression_until((TokenKind.RIGHT_PAREN,))
            self.consume(TokenKind.RIGHT_PAREN, "Expected ')' after print expression")
        else:
            expression = self.parse_expression_until((TokenKind.SEMICOLON,))
        self.consume(TokenKind.SEMICOLON, "Expected ';' after print statement")
        return PrintStatement(location=self.ast_location(start), expression=expression)

    def parse_return_statement(self) -> ReturnStatement:
        start = self.consume(TokenKind.RETURN, "Expected 'return'")
        expression = None
        if not self.check(TokenKind.SEMICOLON):
            expression = self.parse_expression_until((TokenKind.SEMICOLON,))
        self.consume(TokenKind.SEMICOLON, "Expected ';' after return statement")
        return ReturnStatement(location=self.ast_location(start), expression=expression)

    def parse_route_statement(self) -> RouteStatement:
        start = self.consume(TokenKind.ROUTE, "Expected 'route'")
        method_token = self.consume_any(
            (TokenKind.GET, TokenKind.POST, TokenKind.IDENTIFIER),
            "Expected route method after 'route'",
        )
        path_token = self.consume(TokenKind.STRING, "Expected route path string after route method")
        body = self.parse_nested_block()
        return RouteStatement(
            location=self.ast_location(start),
            method=method_token.lexeme.upper(),
            path=str(path_token.literal if path_token.literal is not None else path_token.lexeme.strip('"')),
            body=body,
        )

    def parse_nested_block(self) -> BlockNode:
        from .block_parser import BlockParser

        return BlockParser(self.context).parse_block()

    def parse_expression_or_assignment_statement(self):
        start = self.current
        tokens = self.collect_expression_tokens((TokenKind.SEMICOLON,))
        self.consume(TokenKind.SEMICOLON, "Expected ';' after expression statement")

        equals_index = self.top_level_equal_index(tokens)
        if equals_index is not None and equals_index > 0:
            target = self.expression_from_tokens(tokens[:equals_index])
            value = self.expression_from_tokens(tokens[equals_index + 1 :])
            return AssignmentStatement(location=self.ast_location(start), target=target, value=value)

        return ExpressionStatement(location=self.ast_location(start), expression=self.expression_from_tokens(tokens))

    def parse_expression_until(self, stop_kinds: tuple[TokenKind, ...]) -> Expression | None:
        return self.expression_from_tokens(self.collect_expression_tokens(stop_kinds))

    def collect_expression_tokens(self, stop_kinds: tuple[TokenKind, ...]) -> list[Token]:
        tokens: list[Token] = []
        paren_depth = 0
        bracket_depth = 0
        while not self.is_at_end():
            if paren_depth == 0 and bracket_depth == 0 and self.check(*stop_kinds):
                break
            if self.check(TokenKind.RIGHT_BRACE) and paren_depth == 0 and bracket_depth == 0:
                break
            if self.check(TokenKind.LEFT_PAREN):
                paren_depth += 1
            elif self.check(TokenKind.RIGHT_PAREN):
                if paren_depth == 0:
                    break
                paren_depth -= 1
            elif self.check(TokenKind.LEFT_BRACKET):
                bracket_depth += 1
            elif self.check(TokenKind.RIGHT_BRACKET):
                if bracket_depth == 0:
                    break
                bracket_depth -= 1
            tokens.append(self.advance())
        if paren_depth > 0:
            raise self.error("Unterminated delimiter; expected ')'", expected=(TokenKind.RIGHT_PAREN,))
        if bracket_depth > 0:
            raise self.error("Unterminated delimiter; expected ']'", expected=(TokenKind.RIGHT_BRACKET,))
        return tokens

    def expression_from_tokens(self, tokens: list[Token]) -> Expression | None:
        tokens = [token for token in tokens if token.kind != TokenKind.EOF]
        if not tokens:
            return None
        if len(tokens) == 1:
            return self.single_token_expression(tokens[0])
        joined = " ".join(token.lexeme for token in tokens).strip()
        return IdentifierExpression(location=self.ast_location(tokens[0]), name=joined)

    def single_token_expression(self, token: Token) -> Expression:
        if token.kind == TokenKind.STRING:
            return StringLiteral(location=self.ast_location(token), value=str(token.literal if token.literal is not None else token.lexeme.strip('"')))
        if token.kind == TokenKind.NUMBER:
            return NumberLiteral(location=self.ast_location(token), value=token.literal if token.literal is not None else self.parse_number_lexeme(token.lexeme))
        if token.kind == TokenKind.TRUE:
            return BooleanLiteral(location=self.ast_location(token), value=True)
        if token.kind == TokenKind.FALSE:
            return BooleanLiteral(location=self.ast_location(token), value=False)
        return IdentifierExpression(location=self.ast_location(token), name=token.lexeme)

    @staticmethod
    def parse_number_lexeme(value: str) -> int | float:
        try:
            return int(value)
        except ValueError:
            return float(value)

    @staticmethod
    def top_level_equal_index(tokens: list[Token]) -> int | None:
        paren_depth = 0
        bracket_depth = 0
        for index, token in enumerate(tokens):
            if token.kind == TokenKind.LEFT_PAREN:
                paren_depth += 1
            elif token.kind == TokenKind.RIGHT_PAREN and paren_depth > 0:
                paren_depth -= 1
            elif token.kind == TokenKind.LEFT_BRACKET:
                bracket_depth += 1
            elif token.kind == TokenKind.RIGHT_BRACKET and bracket_depth > 0:
                bracket_depth -= 1
            elif token.kind == TokenKind.EQUAL and paren_depth == 0 and bracket_depth == 0:
                return index
        return None

    @staticmethod
    def ast_location(token: Token) -> ASTSourceLocation:
        return ASTSourceLocation(line=token.location.line, column=token.location.column, index=token.location.index)

    def recover_statement(self) -> None:
        while not self.is_at_end() and not self.check(TokenKind.SEMICOLON, TokenKind.RIGHT_BRACE):
            self.advance()
        if self.check(TokenKind.SEMICOLON):
            self.advance()
