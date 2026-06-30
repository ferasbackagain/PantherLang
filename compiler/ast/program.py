from __future__ import annotations

from dataclasses import dataclass

from .base import ASTNode
from .statements import BlockNode


@dataclass(frozen=True)
class ProgramNode(ASTNode):
    body: tuple[ASTNode, ...] = ()

    def children(self) -> tuple[ASTNode, ...]:
        return tuple(self.body)


@dataclass(frozen=True)
class MainBlockNode(ASTNode):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class WebBlockNode(ASTNode):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class ApiBlockNode(ASTNode):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class AiBlockNode(ASTNode):
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()


@dataclass(frozen=True)
class TestBlockNode(ASTNode):
    name: str = ""
    body: BlockNode | None = None

    def children(self) -> tuple[ASTNode, ...]:
        return (self.body,) if self.body is not None else ()

# Prevent pytest from treating this AST node as a test container when imported.
TestBlockNode.__test__ = False
