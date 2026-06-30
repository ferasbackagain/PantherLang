import json
import subprocess
import sys
from pathlib import Path

import pytest

from compiler.lexer import LexerError, TokenKind, lex_source


def kinds(source: str):
    return [token.kind for token in lex_source(source)]


def test_lex_hello_world_program():
    tokens = lex_source('panther main { print("Hello World") }')
    assert [t.kind for t in tokens] == [
        TokenKind.PANTHER, TokenKind.MAIN, TokenKind.LEFT_BRACE,
        TokenKind.PRINT, TokenKind.LEFT_PAREN, TokenKind.STRING,
        TokenKind.RIGHT_PAREN, TokenKind.RIGHT_BRACE, TokenKind.EOF,
    ]
    assert tokens[5].literal == "Hello World"


def test_lex_api_route():
    ks = kinds('panther api { get "/health" { return { "status": "ok" } } }')
    assert TokenKind.API in ks
    assert TokenKind.GET in ks
    assert TokenKind.RETURN in ks
    assert ks[-1] == TokenKind.EOF


def test_lex_numbers_identifiers_and_operators():
    tokens = lex_source('value = 42 + 3.5 != other')
    assert [t.kind for t in tokens] == [
        TokenKind.IDENTIFIER, TokenKind.EQUAL, TokenKind.NUMBER,
        TokenKind.PLUS, TokenKind.NUMBER, TokenKind.BANG_EQUAL,
        TokenKind.IDENTIFIER, TokenKind.EOF,
    ]
    assert tokens[2].literal == 42
    assert tokens[4].literal == 3.5


def test_comments_are_ignored_and_locations_are_tracked():
    tokens = lex_source('// comment\npanther main')
    assert tokens[0].kind == TokenKind.PANTHER
    assert tokens[0].location.line == 2
    assert tokens[0].location.column == 1


def test_unterminated_string_reports_error():
    with pytest.raises(LexerError) as exc:
        lex_source('print("hello)')
    assert "Unterminated string" in str(exc.value)


def test_lexer_cli_json(tmp_path):
    src = tmp_path / "hello.panther"
    src.write_text('panther main { print("Hello") }', encoding="utf-8")
    proc = subprocess.run([sys.executable, "compiler/lexer/panther_lex.py", str(src), "--json"], text=True, capture_output=True, check=True)
    data = json.loads(proc.stdout)
    assert data["ok"] is True
    assert data["tokens"][0]["kind"] == "PANTHER"
    assert data["tokens"][-1]["kind"] == "EOF"
