#!/usr/bin/env bash
set -Eeuo pipefail

PART_ID="R3_BATCH2_PART3_2_6_PARSER_TESTS"
PART_NAME="R3 Batch 2 Part 3.2.6 - Parser Tests"
STAMP="$(date +%Y%m%d_%H%M%S)"
ROOT="$(pwd)"
BACKUP_DIR=".panther/backups/${PART_ID}_${STAMP}"
MANIFEST_DIR=".panther/manifests"
REPORT_DIR="docs/compiler_runtime/reports"
MANIFEST_FILE="${MANIFEST_DIR}/r3_batch2_part3_2_6_parser_tests_manifest.json"
REPORT_FILE="${REPORT_DIR}/r3_batch2_part3_2_6_parser_tests_report.md"

printf '\n== %s ==\n' "$PART_NAME"
printf 'Project root: %s\n' "$ROOT"

if [[ ! -d "compiler" || ! -d "tests" ]]; then
  echo "ERROR: Run this script from the PantherLang project root."
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$MANIFEST_DIR" "$REPORT_DIR" tests/R3_compiler_runtime docs/compiler_runtime

backup_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$path" "$BACKUP_DIR/$path"
  fi
}

backup_if_exists compiler/ast/program.py
backup_if_exists tests/R3_compiler_runtime/test_r3_batch2_part3_2_6_parser_tests.py
backup_if_exists docs/compiler_runtime/r3_batch2_part3_2_6_parser_tests.md
backup_if_exists "$MANIFEST_FILE"
backup_if_exists "$REPORT_FILE"

required_files=(
  compiler/parser/token_stream.py
  compiler/parser/cursor.py
  compiler/parser/parse_error.py
  compiler/parser/parser_base.py
  compiler/parser/program_parser.py
  compiler/parser/block_parser.py
  compiler/parser/statement_parser.py
  tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py
  tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py
  tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py
  tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py
  tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py
)
for path in "${required_files[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "ERROR: Missing required previous-part artifact: $path"
    echo "Run Parts 3.2.1 through 3.2.5 first."
    exit 1
  fi
done

python - <<'PY'
from pathlib import Path
path = Path('compiler/ast/program.py')
text = path.read_text()
marker = 'class TestBlockNode(ASTNode):\n'
if marker in text and 'TestBlockNode.__test__ = False' not in text:
    text = text.rstrip() + '\n\n# Prevent pytest from treating this AST node as a test container when imported.\nTestBlockNode.__test__ = False\n'
path.write_text(text)
PY

cat > tests/R3_compiler_runtime/test_r3_batch2_part3_2_6_parser_tests.py <<'PY'
from compiler.ast import (
    AiBlockNode,
    ApiBlockNode,
    AssignmentStatement,
    BlockNode,
    ExpressionStatement,
    MainBlockNode,
    NumberLiteral,
    PrintStatement,
    ProgramNode,
    ReturnStatement,
    RouteStatement,
    StringLiteral,
    TestBlockNode,
    WebBlockNode,
    ast_to_dict,
)
from compiler.lexer import TokenKind
from compiler.parser import TokenStream, parse_block, parse_program


def test_parser_suite_accepts_complete_current_surface_program():
    source = '''
    panther main {
        print("Hello Panther");
        answer = 42;
        return answer;
    }
    web {
        route GET "/" { print("home"); }
    }
    api {
        route POST "/items" { return 201; }
    }
    ai {
        print("agent");
    }
    test "smoke" {
        print(true);
    }
    '''
    result = parse_program(source)
    assert result.ok
    assert isinstance(result.node, ProgramNode)
    assert [type(node) for node in result.node.body] == [
        MainBlockNode,
        WebBlockNode,
        ApiBlockNode,
        AiBlockNode,
        TestBlockNode,
    ]
    main = result.node.body[0]
    assert len(main.body.statements) == 3
    assert isinstance(main.body.statements[0], PrintStatement)
    assert isinstance(main.body.statements[1], AssignmentStatement)
    assert isinstance(main.body.statements[2], ReturnStatement)


def test_parser_suite_preserves_route_body_statement_ast():
    result = parse_program('web { route GET "/status" { print("ok"); return 0; } }')
    assert result.ok
    route = result.node.body[0].body.statements[0]
    assert isinstance(route, RouteStatement)
    assert route.method == 'GET'
    assert route.path == '/status'
    assert isinstance(route.body, BlockNode)
    assert isinstance(route.body.statements[0], PrintStatement)
    assert isinstance(route.body.statements[1], ReturnStatement)


def test_parser_suite_serialization_contract_for_program_tree():
    result = parse_program('panther main { print("Hello Panther"); }')
    assert result.ok
    payload = ast_to_dict(result.node)
    assert payload['type'] == 'ProgramNode'
    assert payload['body'][0]['type'] == 'MainBlockNode'
    stmt = payload['body'][0]['body']['statements'][0]
    assert stmt['type'] == 'PrintStatement'
    assert stmt['expression']['type'] == 'StringLiteral'
    assert stmt['expression']['value'] == 'Hello Panther'


def test_parser_suite_source_locations_remain_source_aware():
    source = '\n\n  panther main {\n    print("x");\n  }\n'
    result = parse_program(source)
    assert result.ok
    main = result.node.body[0]
    stmt = main.body.statements[0]
    assert main.location.line == 3
    assert main.location.column == 3
    assert stmt.location.line == 4
    assert stmt.location.column == 5


def test_parser_suite_reports_missing_program_block_close():
    result = parse_program('panther main { print("missing close");')
    assert not result.ok
    assert result.diagnostics
    assert any(TokenKind.RIGHT_BRACE in diagnostic.expected for diagnostic in result.diagnostics)


def test_parser_suite_reports_missing_statement_semicolon():
    result = parse_block('{ print("missing") }')
    assert not result.ok
    assert any(TokenKind.SEMICOLON in diagnostic.expected for diagnostic in result.diagnostics)


def test_parser_suite_recovers_after_bad_top_level_and_continues():
    result = parse_program('garbage ; panther main { print("ok"); }')
    assert not result.ok
    assert len(result.node.body) == 1
    assert isinstance(result.node.body[0], MainBlockNode)


def test_parser_suite_empty_program_is_valid_current_contract():
    result = parse_program('')
    assert result.ok
    assert result.node.body == ()


def test_parser_suite_token_stream_checkpoint_still_supports_speculation():
    stream = TokenStream.from_source('panther main { print("x"); }')
    assert stream.check(TokenKind.PANTHER)
    checkpoint = stream.checkpoint()
    assert stream.advance().kind is TokenKind.PANTHER
    assert stream.advance().kind is TokenKind.MAIN
    stream.rollback(checkpoint)
    assert stream.current.kind is TokenKind.PANTHER


def test_parser_suite_expression_statement_placeholder_contract_until_part_3_3():
    result = parse_block('{ do_work(1, 2); }')
    assert result.ok
    stmt = result.node.statements[0]
    assert isinstance(stmt, ExpressionStatement)
    assert stmt.expression.name == 'do_work ( 1 , 2 )'


def test_parser_suite_string_and_number_literals_are_materialized():
    result = parse_block('{ print("x"); return 7; }')
    assert result.ok
    print_stmt, return_stmt = result.node.statements
    assert isinstance(print_stmt.expression, StringLiteral)
    assert print_stmt.expression.value == 'x'
    assert isinstance(return_stmt.expression, NumberLiteral)
    assert return_stmt.expression.value == 7


def test_parser_suite_test_block_name_and_body_are_preserved():
    result = parse_program('test "parser smoke" { print("ok"); }')
    assert result.ok
    block = result.node.body[0]
    assert isinstance(block, TestBlockNode)
    assert block.name == 'parser smoke'
    assert isinstance(block.body.statements[0], PrintStatement)
PY

cat > docs/compiler_runtime/r3_batch2_part3_2_6_parser_tests.md <<'MD'
# R3 Batch 2 Part 3.2.6 — Parser Tests

This segment consolidates parser verification for the current Recursive Descent Parser Core.

Delivered coverage:

- Full current-surface program parsing across `panther main`, `web`, `api`, `ai`, and `test` blocks
- Route body AST preservation
- Program serialization contract
- Source location stability
- Missing block-close diagnostics
- Missing semicolon diagnostics
- Recovery after invalid top-level tokens
- Empty program contract
- TokenStream checkpoint/rollback regression
- Expression statement placeholder contract pending Part 3.3
- Literal materialization checks
- Test block name/body preservation

The segment also marks `compiler.ast.program.TestBlockNode.__test__ = False` so pytest does not emit collection warnings when the AST class is imported into test modules.
MD

python - <<'PY'
import json
from pathlib import Path
manifest = {
    "part_id": "R3_BATCH2_PART3_2_6_PARSER_TESTS",
    "part_name": "R3 Batch 2 Part 3.2.6 - Parser Tests",
    "status": "implemented_pending_local_run",
    "requires": [
        "R3 Batch 2 Part 3.2.1 - Token Stream",
        "R3 Batch 2 Part 3.2.2 - Parser Infrastructure",
        "R3 Batch 2 Part 3.2.3 - Program Parser",
        "R3 Batch 2 Part 3.2.4 - Block Parser",
        "R3 Batch 2 Part 3.2.5 - Statement Parser",
    ],
    "files": [
        "compiler/ast/program.py",
        "tests/R3_compiler_runtime/test_r3_batch2_part3_2_6_parser_tests.py",
        "docs/compiler_runtime/r3_batch2_part3_2_6_parser_tests.md",
        ".panther/manifests/r3_batch2_part3_2_6_parser_tests_manifest.json",
        "docs/compiler_runtime/reports/r3_batch2_part3_2_6_parser_tests_report.md",
    ],
    "verification": {
        "commands": [
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py -q",
            "python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_6_parser_tests.py -q",
            "python -m pytest tests/R3_compiler_runtime -q",
        ]
    },
    "next": "R3 Batch 2 Part 3.2 Final - Recursive Descent Parser Core Final",
}
Path('.panther/manifests/r3_batch2_part3_2_6_parser_tests_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
PY

cat > "$REPORT_FILE" <<MD
# ${PART_NAME}

Status: implemented.

## Summary

Added the consolidated parser test suite for the Recursive Descent Parser Core through Part 3.2.6.

## Added

- Current full-surface parser smoke coverage
- Top-level block coverage for panther/web/api/ai/test
- Route parsing integration assertions
- AST serialization assertions
- Source-location stability assertions
- Diagnostic and recovery assertions
- TokenStream checkpoint regression
- Statement parser placeholder expression contract coverage
- Pytest collection warning guard for TestBlockNode

## Verification

Run by this bootstrap:

\`\`\`bash
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_6_parser_tests.py -q
python -m pytest tests/R3_compiler_runtime -q
\`\`\`

## Backup

${BACKUP_DIR}

## Next

R3 Batch 2 Part 3.2 Final - Recursive Descent Parser Core Final
MD

printf '\nRunning verification...\n'
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_2_parser_infrastructure.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_3_program_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_4_block_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_5_statement_parser.py -q
python -m pytest tests/R3_compiler_runtime/test_r3_batch2_part3_2_6_parser_tests.py -q
python -m pytest tests/R3_compiler_runtime -q

python - <<'PY'
import json
from pathlib import Path
path = Path('.panther/manifests/r3_batch2_part3_2_6_parser_tests_manifest.json')
data = json.loads(path.read_text())
data['status'] = 'passed'
data['local_verification'] = 'passed'
path.write_text(json.dumps(data, indent=2) + '\n')
PY

printf '\n%s completed successfully.\n' "$PART_NAME"
printf 'Manifest: %s\n' "$MANIFEST_FILE"
printf 'Report: %s\n' "$REPORT_FILE"
printf 'Backup: %s\n' "$BACKUP_DIR"
printf 'Next: R3 Batch 2 Part 3.2 Final - Recursive Descent Parser Core Final\n'
