from __future__ import annotations

from compiler.ast import (
    AssignmentStatement,
    BlockNode,
    BooleanLiteral,
    BreakStatement,
    ContinueStatement,
    ElifBranch,
    Expression,
    ExpressionStatement,
    ForStatement,
    FunctionDeclaration,
    IdentifierExpression,
    IfStatement,
    ImportStatement,
    LoopStatement,
    NullLiteral,
    NumberLiteral,
    PrintStatement,
    ReturnStatement,
    RouteStatement,
    StringLiteral,
    VariableDeclaration,
    WhileStatement,
)
from compiler.ast.base import SourceLocation as ASTSourceLocation
from compiler.lexer import Token, TokenKind

from .parse_error import ParseError
from .parser_base import ParserBase


class StatementParser(ParserBase):
    """Parser stage for concrete block-level statements."""

    STATEMENT_STARTS = (
        TokenKind.PRINT,
        TokenKind.RETURN,
        TokenKind.ROUTE,
        TokenKind.IDENTIFIER,
        TokenKind.LEFT_BRACE,
        TokenKind.LET,
        TokenKind.IF,
        TokenKind.WHILE,
        TokenKind.FOR,
        TokenKind.LOOP,
        TokenKind.BREAK,
        TokenKind.CONTINUE,
        TokenKind.FN,
        TokenKind.IMPORT,
        TokenKind.STRUCT,
        TokenKind.ENUM,
        TokenKind.TRAIT,
        TokenKind.NULL,
        TokenKind.TRUE,
        TokenKind.FALSE,
        TokenKind.STRING,
        TokenKind.NUMBER,
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
        if self.check(TokenKind.LET):
            return self.parse_let_statement()
        if self.check(TokenKind.IF):
            return self.parse_if_statement()
        if self.check(TokenKind.WHILE):
            return self.parse_while_statement()
        if self.check(TokenKind.FOR):
            return self.parse_for_statement()
        if self.check(TokenKind.LOOP):
            return self.parse_loop_statement()
        if self.check(TokenKind.BREAK):
            return self.parse_break_statement()
        if self.check(TokenKind.CONTINUE):
            return self.parse_continue_statement()
        if self.check(TokenKind.FN):
            return self.parse_fn_statement()
        if self.check(TokenKind.IMPORT):
            return self.parse_import_statement()
        if self.check(TokenKind.STRUCT):
            return self.parse_struct_statement()
        if self.check(TokenKind.ENUM):
            return self.parse_enum_statement()
        if self.check(TokenKind.TRAIT):
            return self.parse_trait_statement()
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

    def parse_let_statement(self) -> VariableDeclaration:
        start = self.consume(TokenKind.LET, "Expected 'let'")
        name_token = self.consume(TokenKind.IDENTIFIER, "Expected variable name after 'let'")
        var_type = None
        if self.match(TokenKind.COLON):
            type_token = self.consume(TokenKind.IDENTIFIER, "Expected type name after ':'")
            var_type = type_token.lexeme
        initializer = None
        if self.match(TokenKind.EQUAL):
            initializer = self.parse_expression_until((TokenKind.SEMICOLON,))
        self.consume(TokenKind.SEMICOLON, "Expected ';' after variable declaration")
        return VariableDeclaration(
            location=self.ast_location(start),
            name=name_token.lexeme,
            var_type=var_type,
            initializer=initializer,
        )

    def parse_if_statement(self) -> IfStatement:
        start = self.consume(TokenKind.IF, "Expected 'if'")
        condition = self.parse_expression_until((TokenKind.LEFT_BRACE,))
        then_block = self.parse_nested_block()
        elif_branches = []
        while self.check(TokenKind.ELIF) or (self.check(TokenKind.IDENTIFIER) and self.peek().lexeme == "elif"):
            self.advance()
            elif_cond = self.parse_expression_until((TokenKind.LEFT_BRACE,))
            elif_body = self.parse_nested_block()
            elif_branches.append(ElifBranch(condition=elif_cond, body=elif_body))
        else_block = None
        if self.check(TokenKind.ELSE):
            self.consume(TokenKind.ELSE, "Expected 'else'")
            else_block = self.parse_nested_block()
        return IfStatement(
            location=self.ast_location(start),
            condition=condition,
            then_block=then_block,
            elif_branches=tuple(elif_branches),
            else_block=else_block,
        )

    def parse_while_statement(self) -> WhileStatement:
        start = self.consume(TokenKind.WHILE, "Expected 'while'")
        condition = self.parse_expression_until((TokenKind.LEFT_BRACE,))
        body = self.parse_nested_block()
        return WhileStatement(location=self.ast_location(start), condition=condition, body=body)

    def parse_for_statement(self) -> ForStatement:
        start = self.consume(TokenKind.FOR, "Expected 'for'")
        var_token = self.consume(TokenKind.IDENTIFIER, "Expected loop variable name after 'for'")
        self.consume(TokenKind.IN, "Expected 'in' after loop variable")
        start_expr = self.parse_expression_until((TokenKind.DOT_DOT,))
        self.consume(TokenKind.DOT_DOT, "Expected '..' in range")
        end_expr = self.parse_expression_until((TokenKind.LEFT_BRACE,))
        body = self.parse_nested_block()
        return ForStatement(
            location=self.ast_location(start),
            var=var_token.lexeme,
            start=start_expr,
            end=end_expr,
            body=body,
        )

    def parse_loop_statement(self) -> LoopStatement:
        start = self.consume(TokenKind.LOOP, "Expected 'loop'")
        body = self.parse_nested_block()
        return LoopStatement(location=self.ast_location(start), body=body)

    def parse_break_statement(self) -> BreakStatement:
        start = self.consume(TokenKind.BREAK, "Expected 'break'")
        self.consume(TokenKind.SEMICOLON, "Expected ';' after break")
        return BreakStatement(location=self.ast_location(start))

    def parse_continue_statement(self) -> ContinueStatement:
        start = self.consume(TokenKind.CONTINUE, "Expected 'continue'")
        self.consume(TokenKind.SEMICOLON, "Expected ';' after continue")
        return ContinueStatement(location=self.ast_location(start))

    def parse_fn_statement(self) -> FunctionDeclaration:
        start = self.consume(TokenKind.FN, "Expected 'fn'")
        name_token = self.consume(TokenKind.IDENTIFIER, "Expected function name after 'fn'")
        self.consume(TokenKind.LEFT_PAREN, "Expected '(' after function name")
        params = []
        param_types = []
        if not self.check(TokenKind.RIGHT_PAREN):
            param_token = self.consume(TokenKind.IDENTIFIER, "Expected parameter name")
            param_type = None
            if self.match(TokenKind.COLON):
                type_token = self.consume(TokenKind.IDENTIFIER, "Expected parameter type")
                param_type = type_token.lexeme
            params.append(param_token.lexeme)
            param_types.append(param_type)
            while self.match(TokenKind.COMMA):
                param_token = self.consume(TokenKind.IDENTIFIER, "Expected parameter name after ','")
                param_type = None
                if self.match(TokenKind.COLON):
                    type_token = self.consume(TokenKind.IDENTIFIER, "Expected parameter type")
                    param_type = type_token.lexeme
                params.append(param_token.lexeme)
                param_types.append(param_type)
        self.consume(TokenKind.RIGHT_PAREN, "Expected ')' after parameters")
        return_type = None
        if self.match(TokenKind.COLON):
            type_token = self.consume(TokenKind.IDENTIFIER, "Expected return type name after ':'")
            return_type = type_token.lexeme
        body = self.parse_nested_block()
        return FunctionDeclaration(
            location=self.ast_location(start),
            name=name_token.lexeme,
            params=tuple(params),
            param_types=tuple(param_types),
            return_type=return_type,
            body=body,
        )

    def parse_import_statement(self) -> ImportStatement:
        start = self.consume(TokenKind.IMPORT, "Expected 'import'")
        # Accept IDENTIFIER and keywords as module name parts (for panther.*, web.*, api.*, ai.*, test.* imports)
        def consume_module_part():
            if self.check(TokenKind.IDENTIFIER):
                return self.consume(TokenKind.IDENTIFIER, "Expected module name").lexeme
            elif self.check(TokenKind.PANTHER):
                return self.consume(TokenKind.PANTHER).lexeme
            elif self.check(TokenKind.WEB):
                return self.consume(TokenKind.WEB).lexeme
            elif self.check(TokenKind.API):
                return self.consume(TokenKind.API).lexeme
            elif self.check(TokenKind.AI):
                return self.consume(TokenKind.AI).lexeme
            elif self.check(TokenKind.TEST):
                return self.consume(TokenKind.TEST).lexeme
            else:
                raise self.error("Expected module name")
        
        parts = [consume_module_part()]
        while self.match(TokenKind.DOT):
            parts.append(consume_module_part())
        module_name = ".".join(parts)
        alias = None
        if (self.check(TokenKind.IDENTIFIER) or self.check(TokenKind.PANTHER) or self.check(TokenKind.WEB) or self.check(TokenKind.API) or self.check(TokenKind.AI) or self.check(TokenKind.TEST)) and self.peek().lexeme == "as":
            self.advance()
            # Accept keywords as alias too
            if self.check(TokenKind.IDENTIFIER):
                alias_token = self.consume(TokenKind.IDENTIFIER, "Expected alias name after 'as'")
            elif self.check(TokenKind.PANTHER):
                alias_token = self.consume(TokenKind.PANTHER)
            elif self.check(TokenKind.WEB):
                alias_token = self.consume(TokenKind.WEB)
            elif self.check(TokenKind.API):
                alias_token = self.consume(TokenKind.API)
            elif self.check(TokenKind.AI):
                alias_token = self.consume(TokenKind.AI)
            elif self.check(TokenKind.TEST):
                alias_token = self.consume(TokenKind.TEST)
            else:
                raise self.error("Expected alias name after 'as'")
            alias = alias_token.lexeme
        self.consume(TokenKind.SEMICOLON, "Expected ';' after import statement")
        return ImportStatement(
            location=self.ast_location(start),
            module_name=module_name,
            alias=alias,
        )

    def parse_struct_statement(self):
        start = self.consume(TokenKind.STRUCT, "Expected 'struct'")
        name_token = self.consume(TokenKind.IDENTIFIER, "Expected struct name after 'struct'")
        self.consume(TokenKind.LEFT_BRACE, "Expected '{' after struct name")
        fields = []
        while not self.check(TokenKind.RIGHT_BRACE) and not self.is_at_end():
            field_token = self.consume(TokenKind.IDENTIFIER, "Expected field name")
            field_type = None
            if self.match(TokenKind.COLON):
                type_token = self.consume(TokenKind.IDENTIFIER, "Expected field type after ':'")
                field_type = type_token.lexeme
            fields.append(__import__("compiler.ast.statements", fromlist=["FieldDef"]).FieldDef(
                name=field_token.lexeme, field_type=field_type
            ))
            self.match(TokenKind.COMMA)
        self.consume(TokenKind.RIGHT_BRACE, "Expected '}' after struct fields")
        return __import__("compiler.ast.statements", fromlist=["StructDeclaration"]).StructDeclaration(
            location=self.ast_location(start), name=name_token.lexeme, fields=tuple(fields)
        )

    def parse_enum_statement(self):
        start = self.consume(TokenKind.ENUM, "Expected 'enum'")
        name_token = self.consume(TokenKind.IDENTIFIER, "Expected enum name after 'enum'")
        self.consume(TokenKind.LEFT_BRACE, "Expected '{' after enum name")
        variants = []
        while not self.check(TokenKind.RIGHT_BRACE) and not self.is_at_end():
            variant_token = self.consume(TokenKind.IDENTIFIER, "Expected variant name")
            variants.append(variant_token.lexeme)
            self.match(TokenKind.COMMA)
        self.consume(TokenKind.RIGHT_BRACE, "Expected '}' after enum variants")
        return __import__("compiler.ast.statements", fromlist=["EnumDeclaration"]).EnumDeclaration(
            location=self.ast_location(start), name=name_token.lexeme, variants=tuple(variants)
        )

    def parse_trait_statement(self):
        start = self.consume(TokenKind.TRAIT, "Expected 'trait'")
        name_token = self.consume(TokenKind.IDENTIFIER, "Expected trait name after 'trait'")
        self.consume(TokenKind.LEFT_BRACE, "Expected '{' after trait name")
        methods = []
        while not self.check(TokenKind.RIGHT_BRACE) and not self.is_at_end():
            self.consume(TokenKind.FN, "Expected 'fn' for trait method")
            method_token = self.consume(TokenKind.IDENTIFIER, "Expected method name")
            self.consume(TokenKind.LEFT_PAREN, "Expected '(' after method name")
            params = []
            if not self.check(TokenKind.RIGHT_PAREN):
                param_token = self.consume(TokenKind.IDENTIFIER, "Expected parameter name")
                params.append(param_token.lexeme)
                while self.match(TokenKind.COMMA):
                    param_token = self.consume(TokenKind.IDENTIFIER, "Expected parameter name after ','")
                    params.append(param_token.lexeme)
            self.consume(TokenKind.RIGHT_PAREN, "Expected ')' after parameters")
            return_type = None
            if self.match(TokenKind.COLON):
                type_token = self.consume(TokenKind.IDENTIFIER, "Expected return type")
                return_type = type_token.lexeme
            self.consume(TokenKind.SEMICOLON, "Expected ';' after trait method signature")
            methods.append(__import__("compiler.ast.statements", fromlist=["TraitMethodDef"]).TraitMethodDef(
                name=method_token.lexeme, params=tuple(params), return_type=return_type
            ))
        self.consume(TokenKind.RIGHT_BRACE, "Expected '}' after trait methods")
        return __import__("compiler.ast.statements", fromlist=["TraitDeclaration"]).TraitDeclaration(
            location=self.ast_location(start), name=name_token.lexeme, methods=tuple(methods)
        )

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

        equals_index = self.top_level_assign_index(tokens)
        if equals_index is not None and equals_index > 0:
            target = self.expression_from_tokens(tokens[:equals_index])
            value = self.expression_from_tokens(tokens[equals_index + 1:])

            # Determine the operator
            op_token = tokens[equals_index]
            op = "="
            if op_token.kind == TokenKind.PLUS_EQUAL:
                op = "+="
            elif op_token.kind == TokenKind.MINUS_EQUAL:
                op = "-="
            elif op_token.kind == TokenKind.STAR_EQUAL:
                op = "*="
            elif op_token.kind == TokenKind.SLASH_EQUAL:
                op = "/="
            elif op_token.kind == TokenKind.PERCENT_EQUAL:
                op = "%="

            return AssignmentStatement(
                location=self.ast_location(tokens[0]) if tokens else None,
                target=target,
                value=value,
                operator=op,
            )

        return ExpressionStatement(
            location=self.ast_location(tokens[0]) if tokens else None,
            expression=self.expression_from_tokens(tokens),
        )

    def parse_expression_until(self, stop_kinds: tuple[TokenKind, ...]) -> Expression | None:
        tokens = self.collect_expression_tokens(stop_kinds)
        return self.expression_from_tokens(tokens)

    def collect_expression_tokens(self, stop_kinds: tuple[TokenKind, ...]) -> list[Token]:
        tokens: list[Token] = []
        paren_depth = 0
        bracket_depth = 0
        brace_depth = 0
        while not self.is_at_end():
            if paren_depth == 0 and bracket_depth == 0 and brace_depth == 0 and self.check(*stop_kinds):
                break
            if self.check(TokenKind.LEFT_PAREN):
                paren_depth += 1
            elif self.check(TokenKind.RIGHT_PAREN):
                if paren_depth == 0 and brace_depth == 0:
                    break
                if paren_depth > 0:
                    paren_depth -= 1
            elif self.check(TokenKind.LEFT_BRACKET):
                bracket_depth += 1
            elif self.check(TokenKind.RIGHT_BRACKET):
                if bracket_depth > 0:
                    bracket_depth -= 1
                elif brace_depth == 0 and paren_depth == 0:
                    break
            elif self.check(TokenKind.LEFT_BRACE):
                brace_depth += 1
            elif self.check(TokenKind.RIGHT_BRACE):
                if brace_depth > 0:
                    brace_depth -= 1
                elif paren_depth == 0 and bracket_depth == 0:
                    break
            tokens.append(self.advance())
        if paren_depth > 0:
            raise self.error("Unterminated delimiter; expected ')'", expected=(TokenKind.RIGHT_PAREN,))
        if bracket_depth > 0:
            raise self.error("Unterminated delimiter; expected ']'", expected=(TokenKind.RIGHT_BRACKET,))
        return tokens

    def expression_from_tokens(self, tokens: list[Token]) -> Expression | None:
        from .expression_parser import ExpressionParser

        if not tokens:
            return None
        tokens = [t for t in tokens if t.kind != TokenKind.EOF]
        if not tokens:
            return None
        if len(tokens) == 1:
            from compiler.ast.literals import parse_literal_token
            lit = parse_literal_token(tokens[0])
            if lit is not None:
                return lit.expression
            return IdentifierExpression(location=self.ast_location(tokens[0]), name=tokens[0].lexeme)
        try:
            return ExpressionParser(tokens).parse_required()
        except (ValueError, Exception):
            joined = " ".join(token.lexeme for token in tokens).strip()
            return IdentifierExpression(location=self.ast_location(tokens[0]), name=joined)

    @staticmethod
    def parse_number_lexeme(value: str) -> int | float:
        try:
            return int(value)
        except ValueError:
            return float(value)

    @staticmethod
    def top_level_assign_index(tokens: list[Token]) -> int | None:
        assign_kinds = {
            TokenKind.EQUAL, TokenKind.PLUS_EQUAL, TokenKind.MINUS_EQUAL,
            TokenKind.STAR_EQUAL, TokenKind.SLASH_EQUAL, TokenKind.PERCENT_EQUAL,
        }
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
            elif token.kind in assign_kinds and paren_depth == 0 and bracket_depth == 0:
                return index
        return None

    @staticmethod
    def ast_location(token: Token) -> ASTSourceLocation:
        return ASTSourceLocation(
            line=token.location.line,
            column=token.location.column,
            index=token.location.index,
        )

    def recover_statement(self) -> None:
        while not self.is_at_end() and not self.check(TokenKind.SEMICOLON, TokenKind.RIGHT_BRACE):
            self.advance()
        if self.check(TokenKind.SEMICOLON):
            self.advance()
