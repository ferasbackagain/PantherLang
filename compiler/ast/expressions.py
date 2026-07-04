from __future__ import annotations

from dataclasses import dataclass

from .base import ASTNode


NORMALIZE_MAP: dict[str, str] = {}
OPERATOR_PRECEDENCE: dict[str, int] = {}
UNARY_OPERATORS: set[str] = set()
BINARY_OPERATORS: set[str] = set()
ASSIGNMENT_OPERATORS: set[str] = set()
RIGHT_ASSOCIATIVE_OPERATORS: set[str] = set()


def normalize_operator(operator: str) -> str:
    if operator in NORMALIZE_MAP:
        return NORMALIZE_MAP[operator]
    return operator


def operator_precedence(operator: str) -> int | None:
    return OPERATOR_PRECEDENCE.get(normalize_operator(operator))


def is_unary_operator(operator: str) -> bool:
    return normalize_operator(operator) in UNARY_OPERATORS


def is_binary_operator(operator: str) -> bool:
    return normalize_operator(operator) in BINARY_OPERATORS


def is_assignment_operator(operator: str) -> bool:
    return normalize_operator(operator) in ASSIGNMENT_OPERATORS


def is_right_associative_operator(operator: str) -> bool:
    return normalize_operator(operator) in RIGHT_ASSOCIATIVE_OPERATORS


def _init_operators():
    NORMALIZE_MAP.update({
        "==": "==", "!=": "!=",
        ">": ">", "<": "<", ">=": ">=", "<=": "<=",
        "+": "+", "-": "-", "*": "*", "/": "/", "%": "%",
        "**": "**", "||": "||", "&&": "&&",
        "!": "!", "=": "=",
        "+=": "+=", "-=": "-=", "*=": "*=", "/=": "/=", "%=": "%=",
    })

    OPERATOR_PRECEDENCE.update({
        "||": 1, "&&": 2,
        "==": 3, "!=": 3,
        ">": 4, "<": 4, ">=": 4, "<=": 4,
        "+": 5, "-": 5,
        "*": 6, "/": 6, "%": 6,
        "**": 7,
        "!": 8,
        "=": 0, "+=": 0, "-=": 0, "*=": 0, "/=": 0, "%=": 0,
    })

    UNARY_OPERATORS.update({"!", "-"})
    BINARY_OPERATORS.update({"+", "-", "*", "/", "%", "**", "==", "!=", ">", "<", ">=", "<=", "||", "&&"})
    ASSIGNMENT_OPERATORS.update({"=", "+=", "-=", "*=", "/=", "%="})
    RIGHT_ASSOCIATIVE_OPERATORS.update({"=", "+=", "-=", "*=", "/=", "%=", "**"})


_init_operators()


@dataclass(frozen=True)
class Expression(ASTNode):
    pass


@dataclass(frozen=True)
class IdentifierExpression(Expression):
    name: str = ""


@dataclass(frozen=True)
class StringLiteral(Expression):
    value: str = ""


@dataclass(frozen=True)
class NumberLiteral(Expression):
    value: int | float = 0


@dataclass(frozen=True)
class BooleanLiteral(Expression):
    value: bool = False


@dataclass(frozen=True)
class NullLiteral(Expression):
    value: None = None


@dataclass(frozen=True)
class GroupingExpression(Expression):
    expression: Expression | None = None

    def children(self) -> tuple[Expression, ...]:
        return (self.expression,) if self.expression is not None else ()


@dataclass(frozen=True)
class UnaryExpression(Expression):
    operator: str = ""
    operand: Expression | None = None

    def __post_init__(self) -> None:
        object.__setattr__(self, "operator", normalize_operator(self.operator))

    def children(self) -> tuple[Expression, ...]:
        return (self.operand,) if self.operand is not None else ()


@dataclass(frozen=True)
class BinaryExpression(Expression):
    left: Expression | None = None
    operator: str = ""
    right: Expression | None = None

    def __post_init__(self) -> None:
        object.__setattr__(self, "operator", normalize_operator(self.operator))

    def children(self) -> tuple[Expression, ...]:
        nodes = []
        if self.left is not None:
            nodes.append(self.left)
        if self.right is not None:
            nodes.append(self.right)
        return tuple(nodes)


@dataclass(frozen=True)
class CallExpression(Expression):
    callee: Expression | None = None
    arguments: tuple[Expression, ...] = ()

    def children(self) -> tuple[Expression, ...]:
        nodes = []
        if self.callee is not None:
            nodes.append(self.callee)
        nodes.extend(self.arguments)
        return tuple(nodes)


@dataclass(frozen=True)
class MemberExpression(Expression):
    object: Expression | None = None
    property: str = ""

    def children(self) -> tuple[Expression, ...]:
        return (self.object,) if self.object is not None else ()


@dataclass(frozen=True)
class IndexExpression(Expression):
    object: Expression | None = None
    index: Expression | None = None

    def children(self) -> tuple[Expression, ...]:
        return tuple(x for x in (self.object, self.index) if x is not None)


@dataclass(frozen=True)
class ObjectLiteral(Expression):
    entries: tuple[tuple[str, Expression], ...] = ()

    def children(self) -> tuple[Expression, ...]:
        return tuple(expr for _, expr in self.entries)


@dataclass(frozen=True)
class ArrayLiteral(Expression):
    items: tuple[Expression, ...] = ()

    def children(self) -> tuple[Expression, ...]:
        return tuple(self.items)
