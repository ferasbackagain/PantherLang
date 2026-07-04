from __future__ import annotations

from dataclasses import dataclass

from .base import ASTNode
from .expressions import Expression


@dataclass(frozen=True)
class FieldDef(ASTNode):
    name: str = ""
    field_type: str | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return ()


@dataclass(frozen=True)
class TraitMethodDef(ASTNode):
    name: str = ""
    params: tuple[str, ...] = ()
    return_type: str | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return ()


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
    var_type: str | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.initializer,) if self.initializer is not None else ()


@dataclass(frozen=True)
class AssignmentStatement(Statement):
    target: Expression | None = None
    value: Expression | None = None
    operator: str = "="

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.target, self.value) if x is not None)


@dataclass(frozen=True)
class ElifBranch(ASTNode):
    condition: Expression | None = None
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.condition, self.body) if x is not None)


@dataclass(frozen=True)
class IfStatement(Statement):
    condition: Expression | None = None
    then_block: BlockNode | None = None
    elif_branches: tuple[ElifBranch, ...] = ()
    else_block: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(
            x for x in (self.condition, self.then_block, *self.elif_branches, self.else_block)
            if x is not None
        )


@dataclass(frozen=True)
class WhileStatement(Statement):
    condition: Expression | None = None
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.condition, self.body) if x is not None)


@dataclass(frozen=True)
class ForStatement(Statement):
    var: str = ""
    start: Expression | None = None
    end: Expression | None = None
    step: Expression | None = None
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(x for x in (self.start, self.end, self.step, self.body) if x is not None)


@dataclass(frozen=True)
class LoopStatement(Statement):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class BreakStatement(Statement):
    pass

    def children(self) -> tuple[ASTNode, ...]:
        return ()


@dataclass(frozen=True)
class ContinueStatement(Statement):
    pass

    def children(self) -> tuple[ASTNode, ...]:
        return ()


@dataclass(frozen=True)
class RouteStatement(Statement):
    method: str = "GET"
    path: str = "/"
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class FunctionDeclaration(Statement):
    name: str = ""
    params: tuple[str, ...] = ()
    param_types: tuple[str | None, ...] = ()
    body: BlockNode | None = None
    return_type: str | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class ImportStatement(Statement):
    module_name: str = ""
    alias: str | None = None
    path: str = ""

    def children(self) -> tuple[ASTNode, ...]:
        return ()


@dataclass(frozen=True)
class StructDeclaration(Statement):
    name: str = ""
    fields: tuple[FieldDef, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(self.fields)


@dataclass(frozen=True)
class EnumDeclaration(Statement):
    name: str = ""
    variants: tuple[str, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return ()


@dataclass(frozen=True)
class TraitDeclaration(Statement):
    name: str = ""
    methods: tuple[TraitMethodDef, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(self.methods)
