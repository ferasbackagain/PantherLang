from __future__ import annotations

from dataclasses import dataclass

from compiler.ast import (
    ArrayLiteral,
    BinaryExpression,
    BooleanLiteral,
    CallExpression,
    Expression,
    GroupingExpression,
    IdentifierExpression,
    IndexExpression,
    MemberExpression,
    NullLiteral,
    NumberLiteral,
    ObjectLiteral,
    StringLiteral,
    UnaryExpression,
    is_right_associative_operator,
    is_unary_operator,
    operator_precedence,
)
from compiler.ast.base import SourceLocation as ASTSourceLocation
from compiler.lexer import Token, TokenKind
from compiler.ast.literals import parse_literal_token


TOKEN_OPERATOR_LEXEMES: dict[TokenKind, str] = {
    TokenKind.EQUAL: "=",
    TokenKind.EQUAL_EQUAL: "==",
    TokenKind.BANG_EQUAL: "!=",
    TokenKind.GREATER: ">",
    TokenKind.GREATER_EQUAL: ">=",
    TokenKind.LESS: "<",
    TokenKind.LESS_EQUAL: "<=",
    TokenKind.PLUS: "+",
    TokenKind.MINUS: "-",
    TokenKind.STAR: "*",
    TokenKind.SLASH: "/",
    TokenKind.PERCENT: "%",
    TokenKind.BANG: "!",
}

# Optional lexer extensions added in this batch.  getattr keeps older token
# streams compatible if a user runs Part 2 without regenerating lexer tokens.
for _name, _lexeme in {
    "PERCENT": "%",
    "STAR_STAR": "**",
    "PIPE_PIPE": "||",
    "AMP_AMP": "&&",
    "PLUS_EQUAL": "+=",
    "MINUS_EQUAL": "-=",
    "STAR_EQUAL": "*=",
    "SLASH_EQUAL": "/=",
    "PERCENT_EQUAL": "%=",
}.items():
    _kind = getattr(TokenKind, _name, None)
    if _kind is not None:
        TOKEN_OPERATOR_LEXEMES[_kind] = _lexeme


@dataclass(frozen=True)
class ExpressionParseResult:
    expression: Expression | None
    consumed_all: bool


class ExpressionParser:
    """Pratt expression parser for PantherLang token slices.

    This parser intentionally operates on an already-collected expression token
    list so it can integrate with the existing statement parser without changing
    block/program parsing semantics.  It builds the expression AST introduced in
    Phase 2 Batch 2.1 Part 1: literals, identifiers, unary, grouping, and binary
    expressions.
    """

    def __init__(self, tokens: list[Token]):
        self.tokens = [token for token in tokens if token.kind != TokenKind.EOF]
        self.current = 0

    def parse(self) -> ExpressionParseResult:
        if not self.tokens:
            return ExpressionParseResult(None, True)
        expression = self.parse_precedence(0)
        return ExpressionParseResult(expression, self.is_at_end())

    def parse_required(self) -> Expression:
        result = self.parse()
        if result.expression is None:
            raise ValueError("Expected expression")
        if not result.consumed_all:
            raise ValueError(f"Unexpected token in expression: {self.peek().lexeme!r}")
        return result.expression

    def parse_precedence(self, min_precedence: int) -> Expression:
        left = self.parse_prefix()

        while not self.is_at_end():
            if self.check(TokenKind.LEFT_PAREN):
                token = self.advance()
                args: list[Expression] = []
                if not self.check(TokenKind.RIGHT_PAREN):
                    arg_tokens = self._collect_call_args()
                    for arg in arg_tokens:
                        parsed = self.expression_from_tokens(arg)
                        if parsed is not None:
                            args.append(parsed)
                if self.is_at_end() or self.peek().kind != TokenKind.RIGHT_PAREN:
                    raise ValueError("Expected ')' after call arguments")
                self.advance()
                left = CallExpression(
                    location=self.ast_location(token),
                    callee=left,
                    arguments=tuple(args),
                )
                continue

            if self.check(TokenKind.DOT):
                token = self.advance()
                prop_token = self.advance()
                if prop_token.kind != TokenKind.IDENTIFIER:
                    raise ValueError("Expected property name after '.'")
                left = MemberExpression(
                    location=self.ast_location(token),
                    object=left,
                    property=prop_token.lexeme,
                )
                continue

            if self.check(TokenKind.LEFT_BRACKET):
                token = self.advance()
                index = self.parse_precedence(0)
                if self.is_at_end() or self.peek().kind != TokenKind.RIGHT_BRACKET:
                    raise ValueError("Expected ']' after index expression")
                self.advance()
                left = IndexExpression(
                    location=self.ast_location(token),
                    object=left,
                    index=index,
                )
                continue

            operator = self.current_operator()
            if operator is None:
                break
            precedence = operator_precedence(operator)
            if precedence is None or int(precedence) < min_precedence:
                break

            token = self.advance()
            next_min = int(precedence) if is_right_associative_operator(operator) else int(precedence) + 1
            right = self.parse_precedence(next_min)
            left = BinaryExpression(
                location=self.ast_location(token),
                left=left,
                operator=operator,
                right=right,
            )

        return left

    def parse_prefix(self) -> Expression:
        token = self.advance()
        operator = self.operator_for_token(token)
        if operator is not None and is_unary_operator(operator):
            operand = self.parse_precedence(90)
            return UnaryExpression(location=self.ast_location(token), operator=operator, operand=operand)

        if token.kind == TokenKind.LEFT_PAREN:
            expression = self.parse_precedence(0)
            if self.is_at_end() or self.peek().kind != TokenKind.RIGHT_PAREN:
                raise ValueError("Expected ')' after grouped expression")
            self.advance()
            return GroupingExpression(location=self.ast_location(token), expression=expression)

        if token.kind == TokenKind.LEFT_BRACKET:
            return self._parse_array_literal(token)

        if token.kind == TokenKind.LEFT_BRACE:
            return self._parse_object_literal(token)

        literal = parse_literal_token(token)
        if literal is not None:
            return literal.expression
        if token.kind == TokenKind.IDENTIFIER:
            return IdentifierExpression(location=self.ast_location(token), name=token.lexeme)

        raise ValueError(f"Expected expression, got {token.lexeme!r}")

    def _parse_array_literal(self, token: Token) -> ArrayLiteral:
        items: list[Expression] = []
        if not self.check(TokenKind.RIGHT_BRACKET):
            expr = self.parse_precedence(0)
            if expr is not None:
                items.append(expr)
            while self.check(TokenKind.COMMA):
                self.advance()
                if self.check(TokenKind.RIGHT_BRACKET):
                    break
                expr = self.parse_precedence(0)
                if expr is not None:
                    items.append(expr)
        if self.is_at_end() or self.peek().kind != TokenKind.RIGHT_BRACKET:
            raise ValueError("Expected ']' after array literal")
        self.advance()
        return ArrayLiteral(location=self.ast_location(token), items=tuple(items))

    def _parse_object_literal(self, token: Token) -> ObjectLiteral:
        entries: list[tuple[str, Expression]] = []
        if not self.check(TokenKind.RIGHT_BRACE):
            key_token = self.advance()
            if key_token.kind != TokenKind.IDENTIFIER and key_token.kind != TokenKind.STRING:
                raise ValueError("Expected key name in object literal")
            key = key_token.lexeme if key_token.kind == TokenKind.IDENTIFIER else str(key_token.literal)
            if not self.check(TokenKind.COLON):
                raise ValueError("Expected ':' after object key")
            self.advance()
            value = self.parse_precedence(0)
            if value is not None:
                entries.append((key, value))
            while self.check(TokenKind.COMMA):
                self.advance()
                if self.check(TokenKind.RIGHT_BRACE):
                    break
                key_token = self.advance()
                if key_token.kind != TokenKind.IDENTIFIER and key_token.kind != TokenKind.STRING:
                    raise ValueError("Expected key name in object literal")
                key = key_token.lexeme if key_token.kind == TokenKind.IDENTIFIER else str(key_token.literal)
                if not self.check(TokenKind.COLON):
                    raise ValueError("Expected ':' after object key")
                self.advance()
                value = self.parse_precedence(0)
                if value is not None:
                    entries.append((key, value))
        if self.is_at_end() or self.peek().kind != TokenKind.RIGHT_BRACE:
            raise ValueError("Expected '}' after object literal")
        self.advance()
        return ObjectLiteral(location=self.ast_location(token), entries=tuple(entries))

    def current_operator(self) -> str | None:
        if self.is_at_end():
            return None
        return self.operator_for_token(self.peek())

    @staticmethod
    def operator_for_token(token: Token) -> str | None:
        return TOKEN_OPERATOR_LEXEMES.get(token.kind)

    def check(self, *kinds: TokenKind) -> bool:
        return not self.is_at_end() and self.peek().kind in kinds

    def is_at_end(self) -> bool:
        return self.current >= len(self.tokens)

    def peek(self) -> Token:
        return self.tokens[self.current]

    def advance(self) -> Token:
        token = self.tokens[self.current]
        self.current += 1
        return token

    def _collect_call_args(self) -> list[list[Token]]:
        args: list[list[Token]] = [[]]
        paren_depth = 0
        bracket_depth = 0
        brace_depth = 0
        while not self.is_at_end():
            tok = self.peek()
            if tok.kind == TokenKind.RIGHT_PAREN and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                break
            if tok.kind == TokenKind.COMMA and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                args.append([])
                self.advance()
                continue
            if tok.kind == TokenKind.LEFT_PAREN:
                paren_depth += 1
            elif tok.kind == TokenKind.RIGHT_PAREN:
                paren_depth -= 1
            elif tok.kind == TokenKind.LEFT_BRACKET:
                bracket_depth += 1
            elif tok.kind == TokenKind.RIGHT_BRACKET:
                bracket_depth -= 1
            elif tok.kind == TokenKind.LEFT_BRACE:
                brace_depth += 1
            elif tok.kind == TokenKind.RIGHT_BRACE:
                brace_depth -= 1
            args[-1].append(self.advance())
        return args

    def expression_from_tokens(self, tokens: list[Token]) -> Expression | None:
        from compiler.ast.literals import parse_literal_token
        tokens = [t for t in tokens if t.kind != TokenKind.EOF]
        if not tokens:
            return None
        if len(tokens) == 1:
            lit = parse_literal_token(tokens[0])
            if lit is not None:
                return lit.expression
            if tokens[0].kind == TokenKind.IDENTIFIER:
                return IdentifierExpression(location=self.ast_location(tokens[0]), name=tokens[0].lexeme)
        return ExpressionParser(tokens).parse_required()

    @staticmethod
    def ast_location(token: Token) -> ASTSourceLocation:
        return ASTSourceLocation(line=token.location.line, column=token.location.column, index=token.location.index)

    @staticmethod
    def parse_number_lexeme(value: str) -> int | float:
        try:
            return int(value)
        except ValueError:
            return float(value)


def parse_expression(tokens: list[Token]) -> ExpressionParseResult:
    """Parse a token slice into a PantherLang expression parse result.

    Compatibility wrapper preserved for compiler.parser.__init__ and earlier
    Phase 2 Batch 2.1 integration code.
    """
    return ExpressionParser(tokens).parse()


def parse_required_expression(tokens: list[Token]) -> Expression:
    """Parse a token slice into a required expression or raise ValueError."""
    return ExpressionParser(tokens).parse_required()
