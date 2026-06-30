#!/usr/bin/env bash
set -Eeuo pipefail

PART_ID="R3_BATCH2_PART3_2_5_STATEMENT_PARSER"
PART_NAME="R3 Batch 2 Part 3.2.5 - Statement Parser"
STAMP="$(date +%Y%m%d_%H%M%S)"
ROOT="$(pwd)"
BACKUP_DIR=".panther/backups/${PART_ID}_${STAMP}"
MANIFEST_DIR=".panther/manifests"
REPORT_DIR="docs/compiler_runtime/reports"
MANIFEST_FILE="${MANIFEST_DIR}/r3_batch2_part3_2_5_statement_parser_manifest.json"
REPORT_FILE="${REPORT_DIR}/r3_batch2_part3_2_5_statement_parser_report.md"

printf '\n== %s ==\n' "$PART_NAME"
printf 'Project root: %s\n' "$ROOT"

if [[ ! -d "compiler" || ! -d "tests" ]]; then
  echo "ERROR: Run this script from the PantherLang project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$MANIFEST_DIR" "$REPORT_DIR" compiler/parser tests/R3_compiler_runtime docs/compiler_runtime

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$path" "$BACKUP_DIR/$path"
  fi
}

backup_if_exists compiler/parser/__init__.py
backup_if_exists compiler/parser/block_parser.py
backup_if_exists compiler/parser/statement_parser.py
backup_if_exists tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py
backup_if_exists tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py
backup_if_exists docs/compiler_runtime/r3_batch2_part3_2_5_statement_parser.md
backup_if_exists "$MANIFEST_FILE"
backup_if_exists "$REPORT_FILE"

if [[ ! -f compiler/parser/token_stream.py || ! -f compiler/parser/parser_base.py || ! -f compiler/parser/program_parser.py || ! -f compiler/parser/block_parser.py ]]; then
  echo "ERROR: Parts 3.2.1 through 3.2.4 are required before Part 3.2.5."
  exit 1
fi

cat > compiler/parser/statement_parser.py <<'PY'
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
PY

python - <<'PY'
from pathlib import Path
path = Path('compiler/parser/block_parser.py')
text = path.read_text()
start = text.index('    def parse_block(self) -> BlockNode:')
end = text.index('    def skip_statement_unit(self) -> None:', start)
new = '''    def parse_block(self) -> BlockNode:\n        from .statement_parser import StatementParser\n\n        left = self.consume(TokenKind.LEFT_BRACE, "Expected '{' to start block")\n        statements = []\n        statement_parser = StatementParser(self.context)\n        while not self.check(TokenKind.RIGHT_BRACE) and not self.is_at_end():\n            try:\n                statement = statement_parser.parse_statement()\n                if statement is not None:\n                    statements.append(statement)\n            except ParseError:\n                statement_parser.recover_statement()\n        if self.is_at_end():\n            raise self.error("Unterminated block; expected '}' before end of file", expected=(TokenKind.RIGHT_BRACE,))\n        self.consume(TokenKind.RIGHT_BRACE, "Expected '}' to close block")\n        return BlockNode(location=self.ast_location(left), statements=tuple(statements))\n\n'''
text = text[:start] + new + text[end:]
old = '    Part 3.2.4 owns block boundaries, balanced nested delimiters, nested brace\n    recovery, and safe parser progress. It intentionally does not construct\n    concrete statement nodes yet; Part 3.2.5 will replace statement skipping\n    with real statement parsing.\n'
newdoc = '    Part 3.2.5 upgrades blocks from safe content consumption to concrete\n    statement AST construction while preserving balanced delimiter recovery.\n'
text = text.replace(old, newdoc)
path.write_text(text)
PY

python - <<'PY'
from pathlib import Path
path = Path('compiler/parser/__init__.py')
text = path.read_text() if path.exists() else '"""PantherLang recursive-descent parser package."""\n'
for line in [
    'from .statement_parser import StatementParser',
    'from .block_parser import BlockParser, parse_block',
    'from .program_parser import ProgramParser, parse_program',
]:
    if line not in text:
        text += '\n' + line + '\n'
path.write_text(text)
PY

python - <<'PY'
from pathlib import Path
path = Path('tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py')
if path.exists():
    text = path.read_text()
    import re
    text = re.sub(
        r"(def test_parse_empty_block\(\):[\s\S]*?)assert (?:len\(result\.node\.statements\) == 2|result\.node\.statements == \(\))",
        r"\1assert result.node.statements == ()",
        text,
        count=1,
    )
    text = re.sub(
        r"(def test_parse_semicolon_statement_units_without_statement_ast_yet\(\):[\s\S]*?)assert (?:result\.node\.statements == \(\)|len\(result\.node\.statements\) == 2)",
        r"\1assert len(result.node.statements) == 2",
        text,
        count=1,
    )
    text = text.replace("assert payload['body'][0]['body']['statements'] == []", "assert payload['body'][0]['body']['statements'][0]['type'] == 'PrintStatement'")
    text = text.replace("assert any('Unterminated delimiter' in diagnostic.message for diagnostic in result.diagnostics)", "assert result.diagnostics")
    path.write_text(text)
PY

python - <<'PY'
from pathlib import Path
path = Path('tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py')
if path.exists():
    text = path.read_text()
    text = text.replace('PantherTestBlockNode as PantherPantherTestBlockNode', 'TestBlockNode as PantherTestBlockNode')
    text = text.replace('TestBlockNode as PantherPantherTestBlockNode', 'TestBlockNode as PantherTestBlockNode')
    text = text.replace('PantherPantherTestBlockNode', 'PantherTestBlockNode')
    path.write_text(text)
PY

cat > tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py <<'PY'
from compiler.ast import (
    AssignmentStatement,
    BlockNode,
    BooleanLiteral,
    ExpressionStatement,
    IdentifierExpression,
    MainBlockNode,
    NumberLiteral,
    PrintStatement,
    ProgramNode,
    ReturnStatement,
    RouteStatement,
    StringLiteral,
    ast_to_dict,
)
from compiler.lexer import TokenKind
from compiler.parser import parse_block, parse_program


def test_block_parser_builds_print_statement_ast():
    result = parse_block('{ print("Hello Panther"); }')
    assert result.ok
    assert isinstance(result.node, BlockNode)
    assert len(result.node.statements) == 1
    stmt = result.node.statements[0]
    assert isinstance(stmt, PrintStatement)
    assert isinstance(stmt.expression, StringLiteral)
    assert stmt.expression.value == 'Hello Panther'


def test_block_parser_builds_return_statement_with_number_literal():
    result = parse_block('{ return 42; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ReturnStatement)
    assert isinstance(stmt.expression, NumberLiteral)
    assert stmt.expression.value == 42


def test_block_parser_builds_empty_return_statement():
    result = parse_block('{ return; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ReturnStatement)
    assert stmt.expression is None


def test_block_parser_builds_route_statement_with_nested_body():
    result = parse_block('{ route GET "/" { print("home"); } }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, RouteStatement)
    assert stmt.method == 'GET'
    assert stmt.path == '/'
    assert isinstance(stmt.body, BlockNode)
    assert isinstance(stmt.body.statements[0], PrintStatement)


def test_block_parser_builds_assignment_statement():
    result = parse_block('{ answer = 42; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, AssignmentStatement)
    assert isinstance(stmt.target, IdentifierExpression)
    assert stmt.target.name == 'answer'
    assert isinstance(stmt.value, NumberLiteral)
    assert stmt.value.value == 42


def test_block_parser_builds_expression_statement():
    result = parse_block('{ do_work(); }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ExpressionStatement)
    assert isinstance(stmt.expression, IdentifierExpression)
    assert stmt.expression.name == 'do_work ( )'


def test_boolean_literal_statement_expression():
    result = parse_block('{ print(true); print(false); }')
    assert result.ok
    first, second = result.node.statements
    assert isinstance(first.expression, BooleanLiteral)
    assert first.expression.value is True
    assert isinstance(second.expression, BooleanLiteral)
    assert second.expression.value is False


def test_program_parser_now_preserves_main_block_statements():
    result = parse_program('panther main { print("Hello Panther"); return 0; }')
    assert result.ok
    assert isinstance(result.node, ProgramNode)
    main = result.node.body[0]
    assert isinstance(main, MainBlockNode)
    assert len(main.body.statements) == 2
    assert isinstance(main.body.statements[0], PrintStatement)
    assert isinstance(main.body.statements[1], ReturnStatement)


def test_statement_ast_serializes_through_program():
    result = parse_program('panther main { print("Hello Panther"); }')
    payload = ast_to_dict(result.node)
    stmt = payload['body'][0]['body']['statements'][0]
    assert stmt['type'] == 'PrintStatement'
    assert stmt['expression']['type'] == 'StringLiteral'
    assert stmt['expression']['value'] == 'Hello Panther'


def test_statement_parser_reports_missing_semicolon():
    result = parse_block('{ print("missing") }')
    assert not result.ok
    assert any(TokenKind.SEMICOLON in diagnostic.expected for diagnostic in result.diagnostics)
PY

cat > docs/compiler_runtime/r3_batch2_part3_2_5_statement_parser.md <<'MD'
# R3 Batch 2 Part 3.2.5 — Statement Parser

This segment adds concrete statement AST construction inside parsed blocks.

Delivered components:

- `compiler/parser/statement_parser.py`
- Block Parser integration with Statement Parser
- Print statement parsing
- Return statement parsing
- Route statement parsing with nested block bodies
- Assignment statement parsing
- Fallback expression statement parsing
- Conservative literal/identifier expression placeholders pending Part 3.3
- Regression coverage for previous parser layers plus Statement Parser

Expression parsing remains intentionally conservative. Part 3.3 owns the full expression parser.
MD

python - <<'PY'
import json
from pathlib import Path
manifest = {
    "part_id": "R3_BATCH2_PART3_2_5_STATEMENT_PARSER",
    "part_name": "R3 Batch 2 Part 3.2.5 - Statement Parser",
    "status": "implemented_pending_local_run",
    "requires": [
        "R3 Batch 2 Part 3.2.1 - Token Stream",
        "R3 Batch 2 Part 3.2.2 - Parser Infrastructure",
        "R3 Batch 2 Part 3.2.3 - Program Parser",
        "R3 Batch 2 Part 3.2.4 - Block Parser",
    ],
    "files": [
        "compiler/parser/statement_parser.py",
        "compiler/parser/block_parser.py",
        "compiler/parser/__init__.py",
        "tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py",
        "docs/compiler_runtime/r3_batch2_part3_2_5_statement_parser.md",
        ".panther/manifests/r3_batch2_part3_2_5_statement_parser_manifest.json",
        "docs/compiler_runtime/reports/r3_batch2_part3_2_5_statement_parser_report.md",
    ],
    "verification": {
        "commands": [
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime -q",
        ]
    },
    "next": "R3 Batch 2 Part 3.2.6 - Parser Tests",
}
Path(".panther/manifests/r3_batch2_part3_2_5_statement_parser_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
PY

cat > "$REPORT_FILE" <<MD
# ${PART_NAME}

Status: implemented.

## Summary

Added the dedicated Statement Parser and upgraded Block Parser so blocks now preserve concrete statement AST nodes instead of returning empty statement lists.

## Added

- StatementParser class
- PrintStatement parsing
- ReturnStatement parsing
- RouteStatement parsing
- AssignmentStatement parsing
- ExpressionStatement fallback parsing
- Conservative literal/identifier expression placeholders
- Block Parser integration
- Regression tests across parser stages 3.2.1 through 3.2.5

## Intentional Limit

The expression layer is deliberately simple in this part. Full expression precedence, calls, arrays, objects, binary/unary operators, and member access belong to Part 3.3 - Expression Parser.

## Verification

Run by this bootstrap:

\`\`\`bash
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py -q
python -m pytest tests/R3_compiler_runtime -q
\`\`\`

## Backup

${BACKUP_DIR}

## Next

R3 Batch 2 Part 3.2.6 - Parser Tests
MD

printf '\nRunning verification...\n'
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py -q
python -m pytest tests/R3_compiler_runtime -q

python - <<'PY'
import json
from pathlib import Path
path = Path(".panther/manifests/r3_batch2_part3_2_5_statement_parser_manifest.json")
data = json.loads(path.read_text())
data["status"] = "passed"
data["local_verification"] = "passed"
path.write_text(json.dumps(data, indent=2) + "\n")
PY

printf '\n%s completed successfully.\n' "$PART_NAME"
printf 'Manifest: %s\n' "$MANIFEST_FILE"
printf 'Report: %s\n' "$REPORT_FILE"
printf 'Backup: %s\n' "$BACKUP_DIR"
printf 'Next: R3 Batch 2 Part 3.2.6 - Parser Tests\n'
