#!/usr/bin/env bash
set -Eeuo pipefail

PART_ID="R3_BATCH2_PART3_2_4_BLOCK_PARSER"
PART_NAME="R3 Batch 2 Part 3.2.4 - Block Parser"
STAMP="$(date +%Y%m%d_%H%M%S)"
ROOT="$(pwd)"
BACKUP_DIR=".panther/backups/${PART_ID}_${STAMP}"
MANIFEST_DIR=".panther/manifests"
REPORT_DIR="docs/compiler_runtime/reports"
MANIFEST_FILE="${MANIFEST_DIR}/r3_batch2_part3_2_4_block_parser_manifest.json"
REPORT_FILE="${REPORT_DIR}/r3_batch2_part3_2_4_block_parser_report.md"

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
backup_if_exists compiler/parser/program_parser.py
backup_if_exists tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py
backup_if_exists tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py
backup_if_exists docs/compiler_runtime/r3_batch2_part3_2_4_block_parser.md
backup_if_exists "$MANIFEST_FILE"
backup_if_exists "$REPORT_FILE"

if [[ ! -f compiler/parser/token_stream.py || ! -f compiler/parser/parser_base.py || ! -f compiler/parser/program_parser.py ]]; then
  echo "ERROR: Parts 3.2.1, 3.2.2, and 3.2.3 are required before Part 3.2.4."
  exit 1
fi

cat > compiler/parser/block_parser.py <<'PY'
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
PY

python - <<'PY'
from pathlib import Path
path = Path('compiler/parser/program_parser.py')
text = path.read_text()
if 'from .block_parser import BlockParser' not in text:
    text = text.replace('from .parse_error import ParseError\n', 'from .block_parser import BlockParser\nfrom .parse_error import ParseError\n')
old = '''    def parse_placeholder_block(self) -> BlockNode:\n        """Consume a balanced `{ ... }` block and return an empty BlockNode.\n\n        This preserves parser progress and top-level structure before statement\n        parsing exists. It rejects unterminated blocks and leaves real statement\n        construction to Part 3.2.4/3.2.5.\n        """\n\n        left = self.consume(TokenKind.LEFT_BRACE, "Expected '{' to start block")\n        depth = 1\n        while depth > 0:\n            if self.is_at_end():\n                raise self.error("Unterminated block; expected '}' before end of file", expected=(TokenKind.RIGHT_BRACE,))\n            if self.check(TokenKind.LEFT_BRACE):\n                depth += 1\n                self.advance()\n                continue\n            if self.check(TokenKind.RIGHT_BRACE):\n                depth -= 1\n                self.advance()\n                continue\n            self.advance()\n        return BlockNode(location=self.ast_location(left), statements=())\n'''
new = '''    def parse_placeholder_block(self) -> BlockNode:\n        """Parse a balanced block through the dedicated BlockParser stage.\n\n        Statement construction remains intentionally deferred to Part 3.2.5,\n        but block ownership now lives in `BlockParser` instead of ad-hoc\n        top-level placeholder scanning.\n        """\n\n        return BlockParser(self.context).parse_block()\n'''
if old in text:
    text = text.replace(old, new)
elif 'return BlockParser(self.context).parse_block()' not in text:
    raise SystemExit('Could not patch parse_placeholder_block safely')
path.write_text(text)
PY

python - <<'PY'
from pathlib import Path
path = Path('compiler/parser/__init__.py')
text = path.read_text() if path.exists() else '"""PantherLang recursive-descent parser package."""\n'
for line in [
    'from .block_parser import BlockParser, parse_block',
    'from .program_parser import ProgramParser, parse_program',
]:
    if line not in text:
        text += '\n' + line + '\n'
path.write_text(text)
PY

python - <<'PY'
from pathlib import Path
# Remove pytest collection warning caused by importing AST TestBlockNode under a Test* name in a test module.
path = Path('tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py')
if path.exists():
    text = path.read_text()
    text = text.replace('TestBlockNode', 'PantherTestBlockNode')
    text = text.replace('AiBlockNode, ApiBlockNode, MainBlockNode, ProgramNode, PantherTestBlockNode, WebBlockNode', 'AiBlockNode, ApiBlockNode, MainBlockNode, ProgramNode, TestBlockNode as PantherTestBlockNode, WebBlockNode')
    path.write_text(text)
PY

cat > tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py <<'PY'
from compiler.ast import BlockNode, MainBlockNode, ProgramNode, WebBlockNode, ast_to_dict
from compiler.lexer import TokenKind
from compiler.parser import BlockParser, ProgramParser, parse_block, parse_program


def test_parse_empty_block():
    result = parse_block('{ }')
    assert result.ok
    assert isinstance(result.node, BlockNode)
    assert result.node.statements == ()


def test_parse_semicolon_statement_units_without_statement_ast_yet():
    result = parse_block('{ print("Hello Panther"); return 1; }')
    assert result.ok
    assert isinstance(result.node, BlockNode)
    assert result.node.statements == ()


def test_parse_nested_brace_units_inside_block():
    result = parse_block('{ route GET "/" { print("home"); } print("after"); }')
    assert result.ok
    assert isinstance(result.node, BlockNode)


def test_parse_balanced_parentheses_and_brackets_inside_block():
    result = parse_block('{ print(call([1, 2, 3], "x")); }')
    assert result.ok
    assert isinstance(result.node, BlockNode)


def test_block_parser_reports_unterminated_block():
    result = parse_block('{ print("missing close");')
    assert not result.ok
    assert result.node is None
    assert any('Unterminated block' in diagnostic.message for diagnostic in result.diagnostics)
    assert any(diagnostic.expected == (TokenKind.RIGHT_BRACE,) for diagnostic in result.diagnostics)


def test_block_parser_reports_unterminated_delimiter():
    result = parse_block('{ print(("missing paren"); }')
    assert not result.ok
    assert any('Unterminated delimiter' in diagnostic.message for diagnostic in result.diagnostics)


def test_program_parser_delegates_top_level_bodies_to_block_parser():
    result = parse_program('panther main { route GET "/" { print("x"); } } web { route GET "/" { } }')
    assert result.ok
    assert isinstance(result.node, ProgramNode)
    assert [type(item) for item in result.node.body] == [MainBlockNode, WebBlockNode]
    assert all(isinstance(item.body, BlockNode) for item in result.node.body)


def test_block_ast_serializes_after_program_parse():
    result = parse_program('panther main { print("Hello Panther"); }')
    payload = ast_to_dict(result.node)
    assert payload['type'] == 'ProgramNode'
    assert payload['body'][0]['body']['type'] == 'BlockNode'
    assert payload['body'][0]['body']['statements'] == []


def test_block_parser_class_parse_entrypoint():
    parser = BlockParser.from_source('{ print("x"); }')
    result = parser.parse()
    assert result.ok
    assert isinstance(result.node, BlockNode)


def test_program_parser_still_reports_missing_block_start():
    parser = ProgramParser.from_source('panther main print("x");')
    result = parser.parse()
    assert not result.ok
    assert any(TokenKind.LEFT_BRACE in diagnostic.expected for diagnostic in result.diagnostics)
PY

cat > docs/compiler_runtime/r3_batch2_part3_2_4_block_parser.md <<'MD'
# R3 Batch 2 Part 3.2.4 — Block Parser

This segment adds the dedicated recursive-descent block parser used by the Program Parser.

Delivered components:

- `compiler/parser/block_parser.py`
- `BlockParser.parse()` and `parse_block()` entrypoints
- Balanced `{ ... }` block parsing
- Nested block consumption
- Balanced parenthesis/bracket skipping inside block-level units
- Error reporting for unterminated blocks and unterminated delimiters
- Program Parser delegation to the Block Parser
- Regression coverage for Token Stream, Parser Infrastructure, Program Parser, and Block Parser

This segment intentionally keeps `BlockNode.statements` empty. Concrete statement AST construction belongs to Part 3.2.5 — Statement Parser.
MD

python - <<'PY'
import json
from pathlib import Path
manifest = {
    "part_id": "R3_BATCH2_PART3_2_4_BLOCK_PARSER",
    "part_name": "R3 Batch 2 Part 3.2.4 - Block Parser",
    "status": "implemented_pending_local_run",
    "requires": [
        "R3 Batch 2 Part 3.2.1 - Token Stream",
        "R3 Batch 2 Part 3.2.2 - Parser Infrastructure",
        "R3 Batch 2 Part 3.2.3 - Program Parser",
    ],
    "files": [
        "compiler/parser/block_parser.py",
        "compiler/parser/program_parser.py",
        "compiler/parser/__init__.py",
        "tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py",
        "tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py",
        "docs/compiler_runtime/r3_batch2_part3_2_4_block_parser.md",
        ".panther/manifests/r3_batch2_part3_2_4_block_parser_manifest.json",
        "docs/compiler_runtime/reports/r3_batch2_part3_2_4_block_parser_report.md",
    ],
    "verification": {
        "commands": [
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime -q",
        ]
    },
    "next": "R3 Batch 2 Part 3.2.5 - Statement Parser",
}
Path(".panther/manifests/r3_batch2_part3_2_4_block_parser_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
PY

cat > "$REPORT_FILE" <<MD
# ${PART_NAME}

Status: implemented.

## Summary

Added the dedicated Block Parser layer and wired Program Parser block handling through it.

## Added

- BlockParser class
- parse_block convenience entrypoint
- Balanced block parsing
- Nested block handling
- Balanced parenthesis/bracket skipping
- Unterminated block diagnostics
- Unterminated delimiter diagnostics
- Program Parser delegation to BlockParser
- Regression tests for previous parser layers plus Block Parser

## Intentional Limit

Part 3.2.4 does not build concrete statement nodes. It returns valid empty BlockNode instances while safely consuming block content. Statement AST construction is the responsibility of Part 3.2.5.

## Verification

Run by this bootstrap:

\`\`\`bash
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q
python -m pytest tests/R3_compiler_runtime -q
\`\`\`

## Backup

${BACKUP_DIR}

## Next

R3 Batch 2 Part 3.2.5 - Statement Parser
MD

printf '\nRunning verification...\n'
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q
python -m pytest tests/R3_compiler_runtime -q

python - <<'PY'
import json
from pathlib import Path
path = Path(".panther/manifests/r3_batch2_part3_2_4_block_parser_manifest.json")
data = json.loads(path.read_text())
data["status"] = "passed"
data["local_verification"] = "passed"
path.write_text(json.dumps(data, indent=2) + "\n")
PY

printf '\n%s completed successfully.\n' "$PART_NAME"
printf 'Manifest: %s\n' "$MANIFEST_FILE"
printf 'Report: %s\n' "$REPORT_FILE"
printf 'Backup: %s\n' "$BACKUP_DIR"
printf 'Next: R3 Batch 2 Part 3.2.5 - Statement Parser\n'
