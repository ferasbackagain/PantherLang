from compiler.ast import (
    BinaryExpression,
    BooleanLiteral,
    GroupingExpression,
    IdentifierExpression,
    NullLiteral,
    NumberLiteral,
    StringLiteral,
    UnaryExpression,
)
from compiler.types import (
    AnyType,
    BoolType,
    FloatType,
    IntType,
    NullType,
    StringType,
    TypeChecker,
    check_type,
    get_common_type,
    is_assignable,
)


def test_primitive_types():
    assert IntType.name == "int"
    assert FloatType.name == "float"
    assert StringType.name == "string"
    assert BoolType.name == "bool"
    assert NullType.name == "null"
    assert AnyType.name == "any"


def test_is_assignable_identical():
    assert is_assignable(IntType, IntType)
    assert is_assignable(StringType, StringType)


def test_is_assignable_int_to_float():
    assert is_assignable(IntType, FloatType)


def test_is_assignable_any():
    assert is_assignable(IntType, AnyType)
    assert is_assignable(StringType, AnyType)


def test_is_assignable_mismatch():
    assert not is_assignable(IntType, StringType)
    assert not is_assignable(BoolType, IntType)


def test_get_common_type_identical():
    assert get_common_type(IntType, IntType) is IntType


def test_get_common_type_int_float():
    assert get_common_type(IntType, FloatType) is FloatType
    assert get_common_type(FloatType, IntType) is FloatType


def test_get_common_type_any():
    assert get_common_type(IntType, AnyType) is AnyType


def test_infer_number_literal():
    checker = TypeChecker()
    assert checker.infer_type(NumberLiteral(value=42)) is IntType
    assert checker.infer_type(NumberLiteral(value=3.14)) is FloatType


def test_infer_string_literal():
    checker = TypeChecker()
    assert checker.infer_type(StringLiteral(value="hello")) is StringType


def test_infer_boolean_literal():
    checker = TypeChecker()
    assert checker.infer_type(BooleanLiteral(value=True)) is BoolType


def test_infer_null_literal():
    checker = TypeChecker()
    assert checker.infer_type(NullLiteral()) is NullType


def test_infer_binary_addition():
    checker = TypeChecker()
    expr = BinaryExpression(
        left=NumberLiteral(value=1),
        operator="+",
        right=NumberLiteral(value=2),
    )
    assert checker.infer_type(expr) is IntType


def test_infer_binary_comparison():
    checker = TypeChecker()
    expr = BinaryExpression(
        left=NumberLiteral(value=1),
        operator=">",
        right=NumberLiteral(value=2),
    )
    assert checker.infer_type(expr) is BoolType


def test_infer_unary_not():
    checker = TypeChecker()
    expr = UnaryExpression(operator="!", operand=BooleanLiteral(value=True))
    assert checker.infer_type(expr) is BoolType


def test_infer_unary_minus():
    checker = TypeChecker()
    expr = UnaryExpression(operator="-", operand=NumberLiteral(value=5))
    assert checker.infer_type(expr) is IntType


def test_infer_grouping():
    checker = TypeChecker()
    inner = BinaryExpression(
        left=NumberLiteral(value=1),
        operator="+",
        right=NumberLiteral(value=2),
    )
    expr = GroupingExpression(expression=inner)
    assert checker.infer_type(expr) is IntType


def test_infer_identifier_from_env():
    checker = TypeChecker()
    checker.declare("x", IntType)
    assert checker.infer_type(IdentifierExpression(name="x")) is IntType


def test_type_error_on_bool_arithmetic():
    checker = TypeChecker()
    expr = BinaryExpression(
        left=BooleanLiteral(value=True),
        operator="+",
        right=NumberLiteral(value=1),
    )
    checker.infer_type(expr)
    assert len(checker.diagnostics) >= 1


def test_no_type_error_on_valid_arithmetic():
    checker = TypeChecker()
    expr = BinaryExpression(
        left=NumberLiteral(value=10),
        operator="*",
        right=NumberLiteral(value=2),
    )
    checker.infer_type(expr)
    assert len(checker.diagnostics) == 0


def test_check_type_function():
    result_type, diags = check_type(NumberLiteral(value=7))
    assert result_type is IntType
    assert len(diags) == 0


def test_check_type_with_env():
    result_type, diags = check_type(
        IdentifierExpression(name="y"),
        env={"y": StringType},
    )
    assert result_type is StringType
