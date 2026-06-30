#!/usr/bin/env bash
set -Eeuo pipefail

PART_ID="R3_BATCH2_PART3_2_3_PROGRAM_PARSER"
PART_NAME="R3 Batch 2 Part 3.2.3 - Program Parser"
STAMP="$(date +%Y%m%d_%H%M%S)"
ROOT="$(pwd)"
BACKUP_DIR=".panther/backups/${PART_ID}_${STAMP}"
MANIFEST_DIR=".panther/manifests"
REPORT_DIR="docs/compiler_runtime/reports"
MANIFEST_FILE="${MANIFEST_DIR}/r3_batch2_part3_2_3_program_parser_manifest.json"
REPORT_FILE="${REPORT_DIR}/r3_batch2_part3_2_3_program_parser_report.md"

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
backup_if_exists compiler/parser/program_parser.py
backup_if_exists tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py
backup_if_exists docs/compiler_runtime/r3_batch2_part3_2_3_program_parser.md
backup_if_exists "$MANIFEST_FILE"
backup_if_exists "$REPORT_FILE"

if [[ ! -f compiler/parser/token_stream.py || ! -f compiler/parser/parser_base.py ]]; then
  echo "ERROR: Parts 3.2.1 and 3.2.2 are required before Part 3.2.3."
  exit 1
fi

cat > compiler/parser/program_parser.py <<'PY'
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
        """Consume a balanced `{ ... }` block and return an empty BlockNode.

        This preserves parser progress and top-level structure before statement
        parsing exists. It rejects unterminated blocks and leaves real statement
        construction to Part 3.2.4/3.2.5.
        """

        left = self.consume(TokenKind.LEFT_BRACE, "Expected '{' to start block")
        depth = 1
        while depth > 0:
            if self.is_at_end():
                raise self.error("Unterminated block; expected '}' before end of file", expected=(TokenKind.RIGHT_BRACE,))
            if self.check(TokenKind.LEFT_BRACE):
                depth += 1
                self.advance()
                continue
            if self.check(TokenKind.RIGHT_BRACE):
                depth -= 1
                self.advance()
                continue
            self.advance()
        return BlockNode(location=self.ast_location(left), statements=())

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
PY

python - <<'PY'
from pathlib import Path
path = Path('compiler/parser/__init__.py')
text = path.read_text() if path.exists() else '"""PantherLang recursive-descent parser package."""\n'
if 'from .program_parser import ProgramParser, parse_program' not in text:
    text += '\nfrom .program_parser import ProgramParser, parse_program\n'
if '__all__' in text and 'ProgramParser' not in text:
    text = text.rstrip() + '\n'
path.write_text(text)
PY

cat > tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py <<'PY'
from compiler.ast import AiBlockNode, ApiBlockNode, MainBlockNode, ProgramNode, TestBlockNode, WebBlockNode, ast_to_dict
from compiler.lexer import TokenKind
from compiler.parser import ProgramParser, parse_program


def test_parse_minimal_panther_main_program():
    result = parse_program('panther main { }')
    assert result.ok
    assert isinstance(result.node, ProgramNode)
    assert len(result.node.body) == 1
    assert isinstance(result.node.body[0], MainBlockNode)
    assert result.node.body[0].body.statements == ()


def test_parse_panther_main_with_placeholder_statement_content():
    result = parse_program('panther main { print("Hello Panther"); }')
    assert result.ok
    assert isinstance(result.node.body[0], MainBlockNode)
    assert result.node.body[0].body is not None


def test_parse_multiple_top_level_blocks():
    source = '''
    panther main { print("x"); }
    web { route GET "/" { } }
    api { route POST "/v1" { } }
    ai { prompt "hello"; }
    test "smoke" { assert true; }
    '''
    result = parse_program(source)
    assert result.ok
    assert [type(node) for node in result.node.body] == [
        MainBlockNode,
        WebBlockNode,
        ApiBlockNode,
        AiBlockNode,
        TestBlockNode,
    ]
    assert result.node.body[-1].name == "smoke"


def test_program_parser_records_missing_main_after_panther():
    result = parse_program('panther { }')
    assert not result.ok
    assert result.node.body == ()
    assert any(item.expected == (TokenKind.MAIN,) for item in result.diagnostics)


def test_program_parser_records_unknown_top_level_token_and_recovers():
    result = parse_program('print("bad"); panther main { }')
    assert not result.ok
    assert len(result.node.body) == 1
    assert isinstance(result.node.body[0], MainBlockNode)
    assert any('Expected top-level' in item.message for item in result.diagnostics)


def test_program_parser_rejects_unterminated_block():
    result = parse_program('panther main { print("x");')
    assert not result.ok
    assert result.node.body == ()
    assert any('Unterminated block' in item.message for item in result.diagnostics)


def test_program_ast_serializes_top_level_shape():
    result = parse_program('panther main { }')
    payload = ast_to_dict(result.node)
    assert payload['type'] == 'ProgramNode'
    assert payload['body'][0]['type'] == 'MainBlockNode'
    assert payload['body'][0]['body']['type'] == 'BlockNode'


def test_program_parser_class_parse_entrypoint():
    parser = ProgramParser.from_source('web { }')
    result = parser.parse()
    assert result.ok
    assert isinstance(result.node.body[0], WebBlockNode)
PY

cat > docs/compiler_runtime/r3_batch2_part3_2_3_program_parser.md <<'MD'
# R3 Batch 2 Part 3.2.3 — Program Parser

This segment adds the first concrete recursive-descent parser stage: the top-level `ProgramParser`.

Delivered components:

- `compiler/parser/program_parser.py`
- `ProgramParser.parse()` and `parse_program()` entrypoints
- Top-level parsing for `panther main`, `web`, `api`, `ai`, and `test` blocks
- Balanced placeholder block consumption until the dedicated Block Parser lands in Part 3.2.4
- Recovery to the next top-level block after malformed input
- Program parser tests and AST serialization checks

This segment intentionally does not parse statements inside blocks. It preserves the top-level AST envelope and parser progress so the next parser stages can replace placeholder block handling with real statement parsing.
MD

python - <<'PY'
import json
from pathlib import Path
manifest = {
    "part_id": "R3_BATCH2_PART3_2_3_PROGRAM_PARSER",
    "part_name": "R3 Batch 2 Part 3.2.3 - Program Parser",
    "status": "implemented_pending_local_run",
    "requires": [
        "R3 Batch 2 Part 3.2.1 - Token Stream",
        "R3 Batch 2 Part 3.2.2 - Parser Infrastructure",
    ],
    "files": [
        "compiler/parser/program_parser.py",
        "compiler/parser/__init__.py",
        "tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py",
        "docs/compiler_runtime/r3_batch2_part3_2_3_program_parser.md",
        ".panther/manifests/r3_batch2_part3_2_3_program_parser_manifest.json",
        "docs/compiler_runtime/reports/r3_batch2_part3_2_3_program_parser_report.md",
    ],
    "verification": {
        "commands": [
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime -q",
        ]
    },
    "next": "R3 Batch 2 Part 3.2.4 - Block Parser",
}
Path(".panther/manifests/r3_batch2_part3_2_3_program_parser_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
PY

cat > "$REPORT_FILE" <<MD
# ${PART_NAME}

Status: implemented.

## Summary

Added the concrete top-level recursive-descent Program Parser on top of the completed Token Stream and Parser Infrastructure layers.

## Added

- ProgramParser class
- parse_program convenience entrypoint
- Top-level block parsing for panther main, web, api, ai, and test blocks
- Balanced placeholder block consumption
- Recovery to next top-level declaration
- Tests for valid programs, diagnostics, recovery, and AST serialization

## Verification

Run by this bootstrap:

\`\`\`bash
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q
python -m pytest tests/R3_compiler_runtime -q
\`\`\`

## Backup

${BACKUP_DIR}

## Next

R3 Batch 2 Part 3.2.4 - Block Parser
MD

printf '\nRunning verification...\n'
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q
python -m pytest tests/R3_compiler_runtime -q

python - <<'PY'
import json
from pathlib import Path
path = Path(".panther/manifests/r3_batch2_part3_2_3_program_parser_manifest.json")
data = json.loads(path.read_text())
data["status"] = "passed"
data["local_verification"] = "passed"
path.write_text(json.dumps(data, indent=2) + "\n")
PY

printf '\n%s completed successfully.\n' "$PART_NAME"
printf 'Manifest: %s\n' "$MANIFEST_FILE"
printf 'Report: %s\n' "$REPORT_FILE"
printf 'Backup: %s\n' "$BACKUP_DIR"
printf 'Next: R3 Batch 2 Part 3.2.4 - Block Parser\n'
