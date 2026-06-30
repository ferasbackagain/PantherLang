from __future__ import annotations

from dataclasses import dataclass

from .base import ASTNode
from .expressions import Expression


@dataclass(frozen=True)
class Statement(ASTNode):
    pass


@dataclass(frozen=True)
class BlockNode(Statement):
    statements: tuple[Statement, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(self.statements)


@dataclass(frozen=True)
class PrintStatement(Statement):
    expression: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.expression,) if self.expression is not None else ()


@dataclass(frozen=True)
class ReturnStatement(Statement):
    expression: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.expression,) if self.expression is not None else ()


@dataclass(frozen=True)
class ExpressionStatement(Statement):
    expression: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.expression,) if self.expression is not None else ()


@dataclass(frozen=True)
class VariableDeclaration(Statement):
    name: str = ""
    initializer: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.initializer,) if self.initializer is not None else ()


@dataclass(frozen=True)
class AssignmentStatement(Statement):
    target: Expression | None = None
    value: Expression | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.target, self.value) if x is not None)


@dataclass(frozen=True)
class IfStatement(Statement):
    condition: Expression | None = None
    then_block: BlockNode | None = None
    else_block: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.condition, self.then_block, self.else_block) if x is not None)


@dataclass(frozen=True)
class WhileStatement(Statement):
    condition: Expression | None = None
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.condition, self.body) if x is not None)


@dataclass(frozen=True)
class RouteStatement(Statement):
    method: str = "GET"
    path: str = "/"
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()
