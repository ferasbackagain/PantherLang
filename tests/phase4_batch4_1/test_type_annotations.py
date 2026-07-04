from compiler.ast import (
    BlockNode,
    ExpressionStatement,
    FunctionDeclaration,
    IdentifierExpression,
    NumberLiteral,
    ReturnStatement,
    StringLiteral,
    VariableDeclaration,
)
from compiler.parser import parse_block
from compiler.semantic import SemanticAnalyzer, SymbolKind
from compiler.types import (
    AnyType,
    BoolType,
    FloatType,
    IntType,
    NullType,
    StringType,
    TypeChecker,
    check_type,
    is_assignable,
)


def test_var_type_annotation():
    v = VariableDeclaration(name="x", initializer=NumberLiteral(value=5), var_type="int")
    assert v.var_type == "int"
    assert v.name == "x"


def test_fn_type_annotation():
    fn = FunctionDeclaration(
        name="add",
        params=("a", "b"),
        param_types=("int", "int"),
        return_type="int",
    )
    assert fn.return_type == "int"
    assert fn.param_types == ("int", "int")


def test_type_checker_resolve_type_name():
    tc = TypeChecker()
    assert tc.resolve_type_name("int") is IntType
    assert tc.resolve_type_name("float") is FloatType
    assert tc.resolve_type_name("string") is StringType
    assert tc.resolve_type_name("bool") is BoolType
    assert tc.resolve_type_name("null") is NullType
    assert tc.resolve_type_name("any") is AnyType
    assert tc.resolve_type_name(None) is AnyType
    assert tc.resolve_type_name("unknown") is AnyType


def test_check_variable_typed_declaration_valid():
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=NumberLiteral(value=42), var_type="int")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 0
    assert tc._env.get("x") is IntType


def test_check_variable_typed_declaration_mismatch():
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=StringLiteral(value="hello"), var_type="int")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 1
    assert "Cannot assign" in tc.diagnostics[0].message


def test_check_variable_typed_declaration_int_to_float():
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=NumberLiteral(value=42), var_type="float")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 0


def test_check_variable_untyped_declaration():
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=NumberLiteral(value=42))
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 0
    assert "x" not in tc._env


def test_check_assignment_valid():
    tc = TypeChecker()
    tc.declare("x", IntType)
    assert tc.check_assignment("x", NumberLiteral(value=10))
    assert len(tc.diagnostics) == 0


def test_check_assignment_mismatch():
    tc = TypeChecker()
    tc.declare("x", IntType)
    assert not tc.check_assignment("x", StringLiteral(value="bad"))
    assert len(tc.diagnostics) == 1


def test_check_assignment_to_untyped():
    tc = TypeChecker()
    tc.declare("x", AnyType)
    assert tc.check_assignment("x", StringLiteral(value="ok"))
    assert len(tc.diagnostics) == 0


def test_check_function_declaration_valid():
    tc = TypeChecker()
    body = BlockNode(statements=(ReturnStatement(expression=NumberLiteral(value=5)),))
    stmt = FunctionDeclaration(name="f", params=(), return_type="int", body=body)
    tc.check_function_declaration(stmt)
    assert len(tc.diagnostics) == 0


def test_check_function_declaration_return_mismatch():
    tc = TypeChecker()
    body = BlockNode(statements=(ReturnStatement(expression=StringLiteral(value="bad")),))
    stmt = FunctionDeclaration(name="f", params=(), return_type="int", body=body)
    tc.check_function_declaration(stmt)
    assert len(tc.diagnostics) == 1
    assert "Return type mismatch" in tc.diagnostics[0].message


def test_check_function_declaration_no_return_type():
    tc = TypeChecker()
    body = BlockNode(statements=(ReturnStatement(expression=NumberLiteral(value=5)),))
    stmt = FunctionDeclaration(name="f", params=(), body=body)
    tc.check_function_declaration(stmt)
    assert len(tc.diagnostics) == 0


def test_type_checker_infer_call_function():
    tc = TypeChecker()
    tc.declare_function("add", ("int", "int"), "int")
    from compiler.ast import CallExpression
    result = tc.infer_type(CallExpression(
        callee=IdentifierExpression(name="add"),
        arguments=(NumberLiteral(value=1), NumberLiteral(value=2)),
    ))
    assert result is IntType


def test_type_checker_infer_call_no_return():
    tc = TypeChecker()
    tc.declare_function("log", (), None)
    from compiler.ast import CallExpression
    result = tc.infer_type(CallExpression(
        callee=IdentifierExpression(name="log"),
        arguments=(),
    ))
    assert result is AnyType


def test_semantic_with_type_annotations():
    result = parse_block('{ let x: int = 42; let y: string = "hello"; }')
    assert result.ok
    analyzer = SemanticAnalyzer()
    for stmt in result.node.statements:
        analyzer._visit_statement(stmt)
    assert len(analyzer.diagnostics) == 0


def test_semantic_type_mismatch():
    result = parse_block('{ let x: int = "hello"; }')
    assert result.ok
    analyzer = SemanticAnalyzer()
    for stmt in result.node.statements:
        analyzer._visit_statement(stmt)
    assert len(analyzer.diagnostics) >= 1


def test_parser_let_with_type():
    result = parse_block('{ let x: int = 42; }')
    assert result.ok
    stmt = result.node.statements[0]
    assert stmt.name == "x"
    assert stmt.var_type == "int"


def test_parser_fn_with_types():
    result = parse_block('{ fn add(a: int, b: int): int { return a + b; } }')
    assert result.ok, result.diagnostics
    fn = result.node.statements[0]
    assert fn.name == "add"
    assert fn.params == ("a", "b")
    assert fn.param_types == ("int", "int")
    assert fn.return_type == "int"


def test_parser_fn_without_types():
    result = parse_block('{ fn foo(x, y): int { return x; } }')
    assert result.ok
    fn = result.node.statements[0]
    assert fn.name == "foo"
    assert fn.params == ("x", "y")
    assert fn.param_types == (None, None)
    assert fn.return_type == "int"


def test_parser_fn_with_return_type():
    result = parse_block('{ fn greet(): string { return "hi"; } }')
    assert result.ok
    fn = result.node.statements[0]
    assert fn.return_type == "string"


def test_parser_let_without_type():
    result = parse_block('{ let x = 42; }')
    assert result.ok
    var = result.node.statements[0]
    assert var.var_type is None


def test_semantic_typed_assignment_valid():
    result = parse_block('{ let x: int = 10; x = 20; }')
    assert result.ok
    analyzer = SemanticAnalyzer()
    for stmt in result.node.statements:
        analyzer._visit_statement(stmt)
    assert len(analyzer.diagnostics) == 0


def test_semantic_typed_assignment_invalid():
    result = parse_block('{ let x: int = 10; x = "bad"; }')
    assert result.ok
    analyzer = SemanticAnalyzer()
    for stmt in result.node.statements:
        analyzer._visit_statement(stmt)
    assert len(analyzer.diagnostics) >= 1


def test_semantic_fn_return_type_valid():
    result = parse_block('{ fn five(): int { return 5; } }')
    assert result.ok
    analyzer = SemanticAnalyzer()
    for stmt in result.node.statements:
        analyzer._visit_statement(stmt)
    assert len(analyzer.diagnostics) == 0


def test_semantic_fn_return_type_invalid():
    result = parse_block('{ fn five(): int { return "bad"; } }')
    assert result.ok
    analyzer = SemanticAnalyzer()
    for stmt in result.node.statements:
        analyzer._visit_statement(stmt)
    assert len(analyzer.diagnostics) >= 1


def test_fn_with_typed_params_valid_call():
    tc = TypeChecker()
    tc.declare_function("add", ("int", "int"), "int")
    from compiler.ast import CallExpression
    tc.declare("a", IntType)
    tc.declare("b", IntType)
    result = tc.infer_type(CallExpression(
        callee=IdentifierExpression(name="add"),
        arguments=(IdentifierExpression(name="a"), IdentifierExpression(name="b")),
    ))
    assert result is IntType
    assert len(tc.diagnostics) == 0


def test_int_to_float_allowed():
    tc = TypeChecker()
    tc.declare("x", FloatType)
    assert tc.check_assignment("x", NumberLiteral(value=5))
    assert len(tc.diagnostics) == 0


def test_float_to_int_not_allowed():
    tc = TypeChecker()
    tc.declare("x", IntType)
    assert not tc.check_assignment("x", NumberLiteral(value=3.14))
    assert len(tc.diagnostics) == 1
