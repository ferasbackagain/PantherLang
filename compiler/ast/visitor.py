from __future__ import annotations

from typing import Any

from .base import ASTNode


class ASTVisitor:
    def visit(self, node: ASTNode) -> Any:
        return node.accept(self)

    def generic_visit(self, node: ASTNode) -> Any:
        return [self.visit(child) for child in node.children()]
