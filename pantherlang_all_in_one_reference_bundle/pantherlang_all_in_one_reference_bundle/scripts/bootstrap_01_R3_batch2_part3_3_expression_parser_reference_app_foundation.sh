#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
BATCH="R3_batch2_part3_3_expression_parser_reference_app_foundation"
BACKUP_DIR="$ROOT/.panther_backups/${BATCH}_${STAMP}"
mkdir -p "$BACKUP_DIR" "$ROOT/reports/R3_compiler_runtime" "$ROOT/docs/compiler_runtime" "$ROOT/examples/reference_apps/panther_calculator" "$ROOT/tests/R3_compiler_runtime" "$ROOT/.panther/manifests"
if [[ ! -d "$ROOT/compiler" ]]; then echo "ERROR: Run from PantherLang repo root."; exit 1; fi
backup_file(){ local path="$1"; if [[ -e "$ROOT/$path" ]]; then mkdir -p "$BACKUP_DIR/$(dirname "$path")"; cp -a "$ROOT/$path" "$BACKUP_DIR/$path"; fi; }
for f in compiler/parser/expression_parser.py compiler/parser/statement_parser.py compiler/parser/__init__.py; do backup_file "$f"; done

python3 - <<'PY'
from pathlib import Path
import json, textwrap
root=Path.cwd()
def write(p,s):
    path=root/p; path.parent.mkdir(parents=True, exist_ok=True); path.write_text(textwrap.dedent(s).lstrip(), encoding='utf-8'); print('WROTE', p)
def read(p):
    path=root/p; return path.read_text(encoding='utf-8') if path.exists() else ''
write('compiler/parser/expression_parser.py', r'''
from __future__ import annotations
from compiler.ast import BinaryExpression, BooleanLiteral, Expression, IdentifierExpression, NullLiteral, NumberLiteral, StringLiteral, UnaryExpression
from compiler.ast.base import SourceLocation as ASTSourceLocation
from compiler.lexer import Token, TokenKind
from .parser_base import ParserBase
from .parser_context import ParserContext
from .token_stream import TokenStream

class ExpressionParser(ParserBase):
    def parse_expression(self): return self.parse_equality()
    def parse_equality(self):
        expr=self.parse_comparison()
        while self.match(TokenKind.EQUAL_EQUAL, TokenKind.BANG_EQUAL):
            op=self.previous; expr=BinaryExpression(location=self.ast_location(op), left=expr, operator=op.lexeme, right=self.parse_comparison())
        return expr
    def parse_comparison(self):
        expr=self.parse_term()
        while self.match(TokenKind.GREATER, TokenKind.GREATER_EQUAL, TokenKind.LESS, TokenKind.LESS_EQUAL):
            op=self.previous; expr=BinaryExpression(location=self.ast_location(op), left=expr, operator=op.lexeme, right=self.parse_term())
        return expr
    def parse_term(self):
        expr=self.parse_factor()
        while self.match(TokenKind.PLUS, TokenKind.MINUS):
            op=self.previous; expr=BinaryExpression(location=self.ast_location(op), left=expr, operator=op.lexeme, right=self.parse_factor())
        return expr
    def parse_factor(self):
        expr=self.parse_unary()
        while self.match(TokenKind.STAR, TokenKind.SLASH):
            op=self.previous; expr=BinaryExpression(location=self.ast_location(op), left=expr, operator=op.lexeme, right=self.parse_unary())
        return expr
    def parse_unary(self):
        if self.match(TokenKind.BANG, TokenKind.MINUS):
            op=self.previous; return UnaryExpression(location=self.ast_location(op), operator=op.lexeme, operand=self.parse_unary())
        return self.parse_primary()
    def parse_primary(self):
        if self.match(TokenKind.NUMBER):
            t=self.previous; return NumberLiteral(location=self.ast_location(t), value=t.literal if t.literal is not None else self.parse_number(t.lexeme))
        if self.match(TokenKind.STRING):
            t=self.previous; return StringLiteral(location=self.ast_location(t), value=str(t.literal if t.literal is not None else t.lexeme.strip('"')))
        if self.match(TokenKind.TRUE): return BooleanLiteral(location=self.ast_location(self.previous), value=True)
        if self.match(TokenKind.FALSE): return BooleanLiteral(location=self.ast_location(self.previous), value=False)
        if self.match(TokenKind.IDENTIFIER):
            t=self.previous
            if t.lexeme == 'null': return NullLiteral(location=self.ast_location(t))
            return IdentifierExpression(location=self.ast_location(t), name=t.lexeme)
        if self.match(TokenKind.LEFT_PAREN):
            start=self.previous; expr=self.parse_expression(); self.consume(TokenKind.RIGHT_PAREN, "Expected ')' after expression")
            if expr is None: raise self.error('Expected expression inside parentheses', token=start)
            return expr
        raise self.error('Expected expression', expected=(TokenKind.NUMBER, TokenKind.STRING, TokenKind.IDENTIFIER, TokenKind.LEFT_PAREN))
    @staticmethod
    def parse_number(text):
        try: return int(text)
        except ValueError: return float(text)
    @staticmethod
    def ast_location(token): return ASTSourceLocation(line=token.location.line, column=token.location.column, index=token.location.index)

def parse_expression_tokens(tokens):
    clean=[t for t in tokens if t.kind != TokenKind.EOF]
    if not clean: return None
    eof=Token(TokenKind.EOF, '', None, clean[-1].location)
    return ExpressionParser(ParserContext(TokenStream([*clean, eof]))).parse_expression()
''')
sp=read('compiler/parser/statement_parser.py')
if 'from .expression_parser import parse_expression_tokens' not in sp:
    sp=sp.replace('from .parser_base import ParserBase\n', 'from .parser_base import ParserBase\nfrom .expression_parser import parse_expression_tokens\n')
old='''    def expression_from_tokens(self, tokens: list[Token]) -> Expression | None:\n        tokens = [token for token in tokens if token.kind != TokenKind.EOF]\n        if not tokens:\n            return None\n        if len(tokens) == 1:\n            return self.single_token_expression(tokens[0])\n        joined = " ".join(token.lexeme for token in tokens).strip()\n        return IdentifierExpression(location=self.ast_location(tokens[0]), name=joined)\n'''
new='''    def expression_from_tokens(self, tokens: list[Token]) -> Expression | None:\n        tokens = [token for token in tokens if token.kind != TokenKind.EOF]\n        if not tokens:\n            return None\n        try:\n            return parse_expression_tokens(tokens)\n        except Exception:\n            if len(tokens) == 1:\n                return self.single_token_expression(tokens[0])\n            joined = " ".join(token.lexeme for token in tokens).strip()\n            return IdentifierExpression(location=self.ast_location(tokens[0]), name=joined)\n'''
if old in sp: sp=sp.replace(old,new)
write('compiler/parser/statement_parser.py', sp)
init=read('compiler/parser/__init__.py')
if 'expression_parser' not in init: init+='\nfrom .expression_parser import ExpressionParser, parse_expression_tokens\n'
write('compiler/parser/__init__.py', init)
write('tests/R3_compiler_runtime/test_r3_batch2_part3_3_expression_parser_reference.py', r'''
from compiler.ast import BinaryExpression, NumberLiteral, UnaryExpression
from compiler.lexer import lex_source
from compiler.parser.expression_parser import parse_expression_tokens

def parse(src): return parse_expression_tokens(list(lex_source(src)))
def test_integer_literal():
    node=parse('10'); assert isinstance(node, NumberLiteral); assert node.value == 10
def test_precedence_multiplication_before_addition():
    node=parse('10 + 5 * 2'); assert isinstance(node, BinaryExpression); assert node.operator == '+'; assert isinstance(node.right, BinaryExpression); assert node.right.operator == '*'
def test_parentheses_override_precedence():
    node=parse('(10 + 5) * 2'); assert isinstance(node, BinaryExpression); assert node.operator == '*'; assert isinstance(node.left, BinaryExpression); assert node.left.operator == '+'
def test_unary():
    node=parse('-10 + 5'); assert isinstance(node, BinaryExpression); assert isinstance(node.left, UnaryExpression)
''')
write('examples/reference_apps/panther_calculator/calculator_phase_1_expressions.pan', '// Panther Calculator is a reference app, not the final product.\nprint(10 + 5);\nprint(10 * (8 + 2));\nprint(100 / 4);\nprint(-10 + 15);\n')
write('docs/compiler_runtime/PANTHERLANG_REFERENCE_APP_STRATEGY.md', '# PantherLang Reference Application Strategy\n\nPanther Calculator is not the product goal. It is a reference app used to prove expressions, variables, input, output, conditions, functions, runtime execution, CLI integration, diagnostics, tests, reports, manifests, and backups.\n')
manifest={'batch':'R3 Batch 2 Part 3.3','role':'Expression Parser + Reference App Foundation','policy':'No Feature Without Proof','next':['Variables','Input','Conditions','Functions','Runtime loop']}
write('.panther/manifests/r3_batch2_part3_3_expression_parser_reference_app.json', json.dumps(manifest, indent=2))
PY
python3 -m pytest -q tests/R3_compiler_runtime/test_r3_batch2_part3_3_expression_parser_reference.py
echo "DONE: $BATCH"
echo "Backup: $BACKUP_DIR"
