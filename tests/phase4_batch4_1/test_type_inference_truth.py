from compiler.ast import (
    VariableDeclaration,
    NumberLiteral,
    StringLiteral,
    BinaryExpression,
    IdentifierExpression,
    ArrayLiteral,
    ObjectLiteral,
    NullLiteral,
)
from compiler.types import TypeChecker, IntType, StringType, AnyType, NullType
from compiler.semantic.diagnostics import SemanticDiagnostic
from compiler.semantic.analyzer import SemanticAnalyzer
from compiler.ast import BlockNode, ProgramNode
from compiler.ast.statements import StructDeclaration
from compiler.ast.expressions import MemberExpression
from compiler.runtime.expression_evaluator import _panther_runtime_type_name, _panther_comparable_types, _panther_require_comparison_compatible
from compiler.runtime import execute_source


def test_unknown_explicit_type_returns_diagnostic():
    """S2: Unknown explicit type must produce deterministic diagnostic"""
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=NumberLiteral(value=5), var_type="UnknownType")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 1
    assert "Unknown type" in tc.diagnostics[0].message
    assert tc.diagnostics[0].code == "T001"


def test_unknown_explicit_type_string():
    tc = TypeChecker()
    stmt = VariableDeclaration(name="name", initializer=StringLiteral(value="test"), var_type="NonExistentType")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 1
    diag = tc.diagnostics[0]
    assert "Unknown type" in diag.message


def test_unknown_explicit_type_function_param():
    tc = TypeChecker()
    stmt = VariableDeclaration(name="func", initializer=None, var_type="BadType")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 1


def test_static_null_type_annotation():
    """Test that null type annotation works correctly"""
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=NullLiteral(), var_type="null")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 0
    assert tc._env.get("x") is NullType


def test_static_non_null_type_rejects_null():
    """Test that assigning null to non-null typed variable produces error"""
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=NullLiteral(), var_type="int")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 1


def test_runtime_null_type_name():
    assert _panther_runtime_type_name(None) == "null"
    assert _panther_runtime_type_name(5) == "int"
    assert _panther_runtime_type_name("hello") == "string"
    assert _panther_runtime_type_name(True) == "bool"


def test_runtime_null_comparison_allowed():
    """Test null can be compared with any type for equality"""
    # This should not raise - null == string, null == int, etc. are allowed
    assert _panther_comparable_types(None, "test") is None
    assert _panther_comparable_types(5, None) is None
    assert _panther_comparable_types(None, None) is None


def test_runtime_null_comparison_disallowed_for_ordering():
    """Test null cannot be ordered with other types"""
    # This should raise PT002 - use the correct comparison function
    try:
        _panther_require_comparison_compatible(">", None, 5)
        raise AssertionError("Should have raised")
    except RuntimeError as e:
        assert "PT002" in str(e)


def test_runtime_int_float_comparison_allowed():
    """Test numeric type combination is allowed for comparisons"""
    try:
        _panther_comparable_types(5, 3.14)
        # This should NOT raise - numeric types are comparable
    except RuntimeError:
        raise AssertionError("Numeric types should be comparable")
    try:
        _panther_comparable_types(3.14, 5)
    except RuntimeError:
        raise AssertionError("Numeric types should be comparable")


def test_runtime_bool_comparison_disallowed():
    """Test bool cannot be compared with numeric types"""
    try:
        _panther_comparable_types(True, 5)
        raise AssertionError("Should have raised")
    except RuntimeError as e:
        assert "PT002" in str(e)


def test_runtime_function_runtime_type_error():
    """Test actual runtime type error from expression evaluator"""
    source = '''
    panther main {
        let a = 5 + "hello";
    }
    '''
    result = execute_source(source)
    # This should produce T001 error during semantic analysis
    assert result.error is not None
    assert "Operator '+' requires numeric operands" in result.error


def test_runtime_expression_evaluator_type_errors():
    """Test actual runtime type errors from expression evaluator"""
    source = '''
    panther main {
        let a = 5 + "hello";
    }
    '''
    result = execute_source(source)
    # This should produce PT001 error during execution
    assert result.error is not None


def test_runtime_comparison_type_error():
    """Test runtime comparison type error"""
    source = '''
    panther main {
        let a = 5 > "hello";
    }
    '''
    result = execute_source(source)
    assert result.error is not None


def test_array_type_inference_static():
    """Test array literal type inference in static checker"""
    tc = TypeChecker()
    arr = ArrayLiteral(items=[NumberLiteral(value=1), NumberLiteral(value=2)])
    # Current implementation returns AnyType for arrays
    result = tc.infer_type(arr)
    assert result is AnyType


def test_object_type_inference_static():
    """Test object literal type inference in static checker"""
    tc = TypeChecker()
    obj = ObjectLiteral(entries=[("x", NumberLiteral(value=1))])
    result = tc.infer_type(obj)
    assert result is AnyType


def test_semantic_analyzer_unknown_type():
    """Test SemanticAnalyzer handles unknown type names correctly"""
    # Create a simple program with unknown type
    source = '''
    panther main {
        let x: UnknownType = 5;
    }
    '''
    result = execute_source(source)
    # Should not crash - may error during type checking


def test_type_annotation_with_primitive_type():
    """Test that valid primitive types work correctly"""
    tc = TypeChecker()
    # int annotation
    stmt = VariableDeclaration(name="x", initializer=NumberLiteral(value=5), var_type="int")
    tc.check_variable_declaration(stmt)
    assert tc._env.get("x") is IntType


def test_type_annotation_with_string_type():
    tc = TypeChecker()
    stmt = VariableDeclaration(name="s", initializer=StringLiteral(value="hello"), var_type="string")
    tc.check_variable_declaration(stmt)
    assert tc._env.get("s") is StringType


def test_type_annotation_none():
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=None, var_type=None)
    tc.check_variable_declaration(stmt)
    # Unannotated variable - should not crash


def test_int_float_coercion_allowed_static():
    """Test int to float coercion in static checker"""
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=NumberLiteral(value=5), var_type="float")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 0


def test_float_int_coercion_disallowed_static():
    """Test float to int coercion is not allowed in static checker"""
    tc = TypeChecker()
    stmt = VariableDeclaration(name="x", initializer=NumberLiteral(value=5.5), var_type="int")
    tc.check_variable_declaration(stmt)
    assert len(tc.diagnostics) == 1
