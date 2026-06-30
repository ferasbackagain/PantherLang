import pytest

from compiler.lexer import TokenKind, lex_source
from compiler.parser import ParseError, ParserBase, TokenCursor, TokenStream


def test_token_stream_from_source_tracks_current_and_eof():
    stream = TokenStream.from_source('panther main { print("Hello") }')
    assert stream.current.kind is TokenKind.PANTHER
    assert stream.peek(1).kind is TokenKind.MAIN
    assert stream.peek(100).kind is TokenKind.EOF
    assert stream.slice_kinds()[-1] is TokenKind.EOF


def test_advance_match_consume_and_previous():
    stream = TokenStream.from_source('panther main')
    first = stream.advance()
    assert first.kind is TokenKind.PANTHER
    assert stream.previous.kind is TokenKind.PANTHER
    assert stream.match(TokenKind.MAIN).kind is TokenKind.MAIN
    assert stream.is_at_end()
    assert stream.advance().kind is TokenKind.EOF
    assert stream.position == len(stream.tokens) - 1


def test_checkpoint_and_rollback_support_parser_speculation():
    stream = TokenStream.from_source('panther main { }')
    checkpoint = stream.checkpoint()
    stream.consume(TokenKind.PANTHER)
    stream.consume(TokenKind.MAIN)
    assert stream.position == 2
    stream.rollback(checkpoint)
    assert stream.position == 0
    assert stream.current.kind is TokenKind.PANTHER


def test_consume_reports_structured_parse_error():
    stream = TokenStream.from_source('panther main')
    with pytest.raises(ParseError) as exc:
        stream.consume(TokenKind.PRINT)
    payload = exc.value.to_dict()
    assert payload["token_kind"] == "PANTHER"
    assert payload["expected"] == ["PRINT"]
    assert payload["location"]["line"] == 1


def test_parser_base_delegates_token_navigation():
    parser = ParserBase.from_source('panther main { print("Hello") }')
    assert parser.check(TokenKind.PANTHER)
    parser.consume(TokenKind.PANTHER)
    parser.consume(TokenKind.MAIN)
    parser.consume(TokenKind.LEFT_BRACE)
    assert parser.match(TokenKind.PRINT).kind is TokenKind.PRINT
    assert parser.current.kind is TokenKind.LEFT_PAREN


def test_token_cursor_save_restore_and_bounds():
    cursor = TokenCursor()
    assert cursor.advance(3) == 3
    mark = cursor.save()
    assert cursor.rewind(2) == 1
    cursor.restore(mark)
    assert cursor.position == 3
    with pytest.raises(ValueError):
        cursor.restore(-1)


def test_token_stream_requires_eof_guard():
    tokens = lex_source('panther main')[:-1]
    with pytest.raises(ValueError):
        TokenStream(tokens)


def test_synchronize_moves_to_statement_boundary():
    parser = ParserBase.from_source('value + + print("ok")')
    parser.synchronize()
    assert parser.current.kind in {TokenKind.PRINT, TokenKind.EOF}
