import pytest

from compiler.lexer import TokenKind
from compiler.parser import DiagnosticSeverity, ParserBase, ParserContext, ParserResult, TokenStream
from compiler.parser.diagnostics import DiagnosticBag


class DemoParser(ParserBase):
    def parse_panther_main_header(self):
        self.consume(TokenKind.PANTHER)
        self.consume(TokenKind.MAIN)
        return "header"


def test_parser_context_wraps_stream_and_checkpoints():
    stream = TokenStream.from_source("panther main { }")
    context = ParserContext(stream)
    mark = context.checkpoint()
    context.stream.advance()
    context.stream.advance()
    assert context.stream.current.kind is TokenKind.LEFT_BRACE
    context.rollback(mark)
    assert context.stream.current.kind is TokenKind.PANTHER


def test_diagnostic_bag_serializes_error_payload():
    stream = TokenStream.from_source("panther")
    bag = DiagnosticBag()
    diagnostic = bag.error("Expected main", stream.current, expected=(TokenKind.MAIN,), code="PARSER_EXPECTED_MAIN")
    assert bag.has_errors
    assert diagnostic.severity is DiagnosticSeverity.ERROR
    payload = bag.to_list()[0]
    assert payload["code"] == "PARSER_EXPECTED_MAIN"
    assert payload["expected"] == ["MAIN"]
    assert payload["token_kind"] == "PANTHER"


def test_parser_base_optional_rolls_back_errors_and_position():
    parser = DemoParser.from_source("print")
    result = parser.optional(parser.parse_panther_main_header)
    assert result is None
    assert parser.current.kind is TokenKind.PRINT
    assert parser.errors == []
    assert parser.diagnostics.diagnostics == []


def test_parser_base_optional_commits_successful_parse():
    parser = DemoParser.from_source("panther main { }")
    result = parser.optional(parser.parse_panther_main_header)
    assert result == "header"
    assert parser.current.kind is TokenKind.LEFT_BRACE
    assert not parser.diagnostics.has_errors


def test_expect_is_non_throwing_and_records_diagnostic():
    parser = ParserBase.from_source("panther")
    token = parser.expect(TokenKind.MAIN, "Expected main after panther")
    assert token is None
    assert parser.current.kind is TokenKind.PANTHER
    assert parser.diagnostics.has_errors
    assert parser.diagnostics.to_list()[0]["message"] == "Expected main after panther"


def test_recover_to_advances_to_requested_boundary():
    parser = ParserBase.from_source('alpha + + print("ok")')
    parser.recover_to(TokenKind.PRINT)
    assert parser.current.kind is TokenKind.PRINT


def test_parser_result_reports_success_and_failure():
    ok = ParserResult(node="program")
    assert ok.ok
    assert not ok.has_errors

    parser = ParserBase.from_source("panther")
    parser.diagnostic("expected main", expected=(TokenKind.MAIN,))
    failed = parser.result(None)
    assert not failed.ok
    assert failed.has_errors
    assert failed.to_dict()["diagnostics"][0]["expected"] == ["MAIN"]


def test_parser_base_consume_still_raises_for_strict_paths():
    parser = ParserBase.from_source("panther")
    with pytest.raises(Exception):
        parser.consume(TokenKind.MAIN)
    assert parser.diagnostics.has_errors
