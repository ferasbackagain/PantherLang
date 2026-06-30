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
