from __future__ import annotations

from dataclasses import dataclass

from .base import ASTNode


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
class UnaryExpression(Expression):
    operator: str = ""
    operand: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.operand,) if self.operand is not None else ()


@dataclass(frozen=True)
class BinaryExpression(Expression):
    left: Expression | None = None
    operator: str = ""
    right: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
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

    def children(self) -> tuple[ASTNode, ...]:
        nodes = []
        if self.callee is not None:
            nodes.append(self.callee)
        nodes.extend(self.arguments)
        return tuple(nodes)


@dataclass(frozen=True)
class MemberExpression(Expression):
    object: Expression | None = None
    property: str = ""

    def children(self) -> tuple[ASTNode, ...]:
        return (self.object,) if self.object is not None else ()


@dataclass(frozen=True)
class ObjectLiteral(Expression):
    entries: tuple[tuple[str, Expression], ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(expr for _, expr in self.entries)


@dataclass(frozen=True)
class ArrayLiteral(Expression):
    items: tuple[Expression, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(self.items)
