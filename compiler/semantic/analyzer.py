from __future__ import annotations

from typing import Any

from compiler.ast import (
    ArrayLiteral,
    AssignmentStatement,
    BlockNode,
    BreakStatement,
    CallExpression,
    ContinueStatement,
    EnumDeclaration,
    ExpressionStatement,
    ForStatement,
    FunctionDeclaration,
    FunctionLiteral,
    IdentifierExpression,
    IfStatement,
    ImportStatement,
    IndexExpression,
    LoopStatement,
    MemberExpression,
    ObjectLiteral,
    PrintStatement,
    ReturnStatement,
    Statement,
    StructDeclaration,
    TraitDeclaration,
    VariableDeclaration,
    WhileStatement,
)
from compiler.ast.base import ASTNode
from compiler.ast.program import ProgramNode
from compiler.types import TypeChecker as TypeChecker_

from .diagnostics import SemanticDiagnostic, SemanticError
from .scope import SymbolKind
from .symbol_table import SymbolTable


class SemanticAnalyzer:
    def __init__(self) -> None:
        self.symbols = SymbolTable()
        self.diagnostics: list[SemanticDiagnostic] = []
        self._in_loop = 0
        self._type_checker = TypeChecker_()
        self._register_stdlib_symbols()

    def _register_stdlib_symbols(self) -> None:
        try:
            from compiler.stdlib import get_stdlib_functions
            for name in get_stdlib_functions():
                try:
                    self.symbols.declare(name, SymbolKind.FUNCTION, location=None)
                except Exception:
                    pass
        except Exception:
            pass

    def analyze(self, node: ASTNode) -> None:
        if isinstance(node, BlockNode):
            self._visit_block(node)
        elif isinstance(node, ProgramNode):
            self._visit_program(node)
        else:
            self._visit_statement(node)

    def _visit_statement(self, stmt: Statement) -> None:
        if isinstance(stmt, VariableDeclaration):
            self._visit_variable_declaration(stmt)
        elif isinstance(stmt, FunctionDeclaration):
            self._visit_function_declaration(stmt)
        elif isinstance(stmt, StructDeclaration):
            self._visit_struct_declaration(stmt)
        elif isinstance(stmt, EnumDeclaration):
            self._visit_enum_declaration(stmt)
        elif isinstance(stmt, TraitDeclaration):
            self._visit_trait_declaration(stmt)
        elif isinstance(stmt, ImportStatement):
            self._visit_import(stmt)
        elif isinstance(stmt, AssignmentStatement):
            self._visit_assignment(stmt)
        elif isinstance(stmt, PrintStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, ReturnStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, ExpressionStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, IfStatement):
            self._visit_if(stmt)
        elif isinstance(stmt, WhileStatement):
            self._visit_while(stmt)
        elif isinstance(stmt, ForStatement):
            self._visit_for(stmt)
        elif isinstance(stmt, LoopStatement):
            self._visit_loop(stmt)
        elif isinstance(stmt, BreakStatement):
            if self._in_loop == 0:
                self.diagnostics.append(SemanticError(
                    message="'break' outside loop",
                    code="E001",
                    location=_loc(stmt),
                ))
        elif isinstance(stmt, ContinueStatement):
            if self._in_loop == 0:
                self.diagnostics.append(SemanticError(
                    message="'continue' outside loop",
                    code="E002",
                    location=_loc(stmt),
                ))
        elif isinstance(stmt, BlockNode):
            self._visit_block(stmt)

    def _visit_block(self, block: BlockNode) -> None:
        self.symbols.enter_scope()

        # Pass 1: Register all declarations in this block
        for s in block.statements:
            self._register_declaration(s)

        # Pass 2: Visit bodies/initializers
        for s in block.statements:
            self._visit_statement_body(s)

        self.symbols.exit_scope()

    def _register_declaration(self, stmt: Statement) -> None:
        """Register a declaration without visiting its body."""
        if isinstance(stmt, VariableDeclaration):
            try:
                self.symbols.declare(stmt.name, SymbolKind.VARIABLE, _loc(stmt))
            except Exception as exc:
                self.diagnostics.append(SemanticError(
                    message=str(exc),
                    code="E003",
                    location=_loc(stmt),
                ))
        elif isinstance(stmt, FunctionDeclaration):
            try:
                # Just declare the function name in current scope, don't create function scope yet
                self.symbols.declare(stmt.name, SymbolKind.FUNCTION, _loc(stmt))
                # NOTE: Return type checking is deferred to pass 2 when function scope exists
            except Exception as exc:
                self.diagnostics.append(SemanticError(
                    message=str(exc),
                    code="E004",
                    location=_loc(stmt),
                ))
        elif isinstance(stmt, StructDeclaration):
            existing = self.symbols.lookup_local(stmt.name)
            if existing is not None:
                self.diagnostics.append(SemanticError(
                    message=f"Duplicate type '{stmt.name}'",
                    code="E005",
                    location=_loc(stmt),
                ))
                return
            self.symbols.declare(stmt.name, SymbolKind.TYPE, _loc(stmt))
        elif isinstance(stmt, EnumDeclaration):
            existing = self.symbols.lookup_local(stmt.name)
            if existing is not None:
                self.diagnostics.append(SemanticError(
                    message=f"Duplicate type '{stmt.name}'",
                    code="E005",
                    location=_loc(stmt),
                ))
                return
            self.symbols.declare(stmt.name, SymbolKind.TYPE, _loc(stmt))
        elif isinstance(stmt, TraitDeclaration):
            existing = self.symbols.lookup_local(stmt.name)
            if existing is not None:
                self.diagnostics.append(SemanticError(
                    message=f"Duplicate type '{stmt.name}'",
                    code="E005",
                    location=_loc(stmt),
                ))
                return
            self.symbols.declare(stmt.name, SymbolKind.TYPE, _loc(stmt))
        elif isinstance(stmt, ImportStatement):
            name = stmt.alias if stmt.alias is not None else stmt.module_name.split(".")[-1]
            existing = self.symbols.lookup_local(name)
            if existing is not None and existing.kind != SymbolKind.FUNCTION:
                self.diagnostics.append(SemanticError(
                    message=f"Duplicate symbol '{name}'",
                    code="E006",
                    location=_loc(stmt),
                ))
            try:
                # Register import alias at global scope so it persists beyond block scope
                self.symbols.declare_global(name, SymbolKind.MODULE, _loc(stmt))
            except Exception:
                pass

    def _visit_statement_body(self, stmt: Statement) -> None:
        """Visit the body/initializer of a statement after all declarations are registered."""
        if isinstance(stmt, VariableDeclaration):
            self._visit_expression(stmt.initializer)
            self._type_checker.check_variable_declaration(stmt)
            self.diagnostics.extend(self._type_checker.diagnostics)
            self._type_checker.diagnostics.clear()
        elif isinstance(stmt, FunctionDeclaration):
            self.symbols.create_function_scope(stmt.name, stmt.params, declare=False)
            for i, param in enumerate(stmt.params):
                p_type = stmt.param_types[i] if i < len(stmt.param_types) else None
                if p_type is not None:
                    self._type_checker.declare(param, self._type_checker.resolve_type_name(p_type))
            # Check return types now that function scope exists
            self._type_checker.check_function_declaration(stmt)
            self.diagnostics.extend(self._type_checker.diagnostics)
            self._type_checker.diagnostics.clear()
            for s in (stmt.body or BlockNode()).statements:
                self._visit_statement(s)
            self.symbols.exit_scope()
        elif isinstance(stmt, AssignmentStatement):
            self._visit_assignment(stmt)
        elif isinstance(stmt, PrintStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, ReturnStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, ExpressionStatement):
            self._visit_expression(stmt.expression)
        elif isinstance(stmt, IfStatement):
            self._visit_if(stmt)
        elif isinstance(stmt, WhileStatement):
            self._visit_while(stmt)
        elif isinstance(stmt, ForStatement):
            self._visit_for(stmt)
        elif isinstance(stmt, LoopStatement):
            self._visit_loop(stmt)
        elif isinstance(stmt, BreakStatement):
            if self._in_loop == 0:
                self.diagnostics.append(SemanticError(
                    message="'break' outside loop",
                    code="E001",
                    location=_loc(stmt),
                ))
        elif isinstance(stmt, ContinueStatement):
            if self._in_loop == 0:
                self.diagnostics.append(SemanticError(
                    message="'continue' outside loop",
                    code="E002",
                    location=_loc(stmt),
                ))
        elif isinstance(stmt, BlockNode):
            self._visit_block(stmt)
        elif isinstance(stmt, ImportStatement):
            self._visit_import(stmt)
        elif isinstance(stmt, (StructDeclaration, EnumDeclaration, TraitDeclaration)):
            pass
        else:
            self._visit_statement(stmt)

    def _visit_variable_declaration(self, stmt: VariableDeclaration) -> None:
        try:
            self.symbols.declare(stmt.name, SymbolKind.VARIABLE, _loc(stmt))
        except Exception as exc:
            self.diagnostics.append(SemanticError(
                message=str(exc),
                code="E003",
                location=_loc(stmt),
            ))
        self._visit_expression(stmt.initializer)
        self._type_checker.check_variable_declaration(stmt)
        self.diagnostics.extend(self._type_checker.diagnostics)
        self._type_checker.diagnostics.clear()

    def _visit_function_declaration(self, stmt: FunctionDeclaration) -> None:
        try:
            self.symbols.create_function_scope(stmt.name, stmt.params, declare=False)
            self._type_checker.check_function_declaration(stmt)
            self.diagnostics.extend(self._type_checker.diagnostics)
            self._type_checker.diagnostics.clear()
            for i, param in enumerate(stmt.params):
                p_type = stmt.param_types[i] if i < len(stmt.param_types) else None
                if p_type is not None:
                    self._type_checker.declare(param, self._type_checker.resolve_type_name(p_type))
            for s in (stmt.body or BlockNode()).statements:
                self._visit_statement(s)
            self.symbols.exit_scope()
        except Exception as exc:
            self.diagnostics.append(SemanticError(
                message=str(exc),
                code="E004",
                location=_loc(stmt),
            ))

    def _visit_struct_declaration(self, stmt: StructDeclaration) -> None:
        existing = self.symbols.lookup_local(stmt.name)
        if existing is not None:
            self.diagnostics.append(SemanticError(
                message=f"Duplicate type '{stmt.name}'",
                code="E005",
                location=_loc(stmt),
            ))
            return
        self.symbols.declare(stmt.name, SymbolKind.TYPE, _loc(stmt))

    def _visit_enum_declaration(self, stmt: EnumDeclaration) -> None:
        existing = self.symbols.lookup_local(stmt.name)
        if existing is not None:
            self.diagnostics.append(SemanticError(
                message=f"Duplicate type '{stmt.name}'",
                code="E005",
                location=_loc(stmt),
            ))
            return
        self.symbols.declare(stmt.name, SymbolKind.TYPE, _loc(stmt))

    def _visit_trait_declaration(self, stmt: TraitDeclaration) -> None:
        existing = self.symbols.lookup_local(stmt.name)
        if existing is not None:
            self.diagnostics.append(SemanticError(
                message=f"Duplicate type '{stmt.name}'",
                code="E005",
                location=_loc(stmt),
            ))
            return
        self.symbols.declare(stmt.name, SymbolKind.TYPE, _loc(stmt))

    def _visit_import(self, stmt: ImportStatement) -> None:
        name = stmt.alias if stmt.alias is not None else stmt.module_name.split(".")[-1]
        # Alias already declared in Pass 1; just register package functions
        try:
            from compiler.stdlib.package_loader import resolve_package
            pkg = resolve_package(stmt.module_name)
            if pkg is not None:
                for fn_name in pkg.functions:
                    try:
                        self.symbols.declare(fn_name, SymbolKind.FUNCTION, None)
                    except Exception:
                        pass
                    # Also register short name (without panther_<pkg>_ prefix)
                    prefix = f"panther_{pkg.name}_"
                    if fn_name.startswith(prefix):
                        short_name = fn_name[len(prefix):]
                        try:
                            self.symbols.declare(short_name, SymbolKind.FUNCTION, None)
                        except Exception:
                            pass
        except Exception:
            pass

    def _visit_assignment(self, stmt: AssignmentStatement) -> None:
        if isinstance(stmt.target, IdentifierExpression):
            if self.symbols.lookup(stmt.target.name) is None:
                self.diagnostics.append(SemanticError(
                    message=f"Undefined variable '{stmt.target.name}'",
                    code="E007",
                    location=_loc(stmt),
                ))
            if stmt.value is not None:
                self._type_checker.check_assignment(stmt.target.name, stmt.value)
                self.diagnostics.extend(self._type_checker.diagnostics)
                self._type_checker.diagnostics.clear()
        self._visit_expression(stmt.value)

    def _visit_if(self, stmt: IfStatement) -> None:
        self._visit_expression(stmt.condition)
        if stmt.then_block is not None:
            self._visit_block(stmt.then_block)
        for elif_branch in stmt.elif_branches:
            self._visit_expression(elif_branch.condition)
            if elif_branch.body is not None:
                self._visit_block(elif_branch.body)
        if stmt.else_block is not None:
            self._visit_block(stmt.else_block)

    def _visit_while(self, stmt: WhileStatement) -> None:
        self._visit_expression(stmt.condition)
        self._in_loop += 1
        if stmt.body is not None:
            self._visit_block(stmt.body)
        self._in_loop -= 1

    def _visit_for(self, stmt: ForStatement) -> None:
        self._visit_expression(stmt.start)
        self._visit_expression(stmt.end)
        self.symbols.enter_scope()
        self.symbols.declare(stmt.var, SymbolKind.VARIABLE)
        self._in_loop += 1
        if stmt.body is not None:
            for s in stmt.body.statements:
                self._visit_statement(s)
        self._in_loop -= 1
        self.symbols.exit_scope()

    def _visit_loop(self, stmt: LoopStatement) -> None:
        self._in_loop += 1
        if stmt.body is not None:
            self._visit_block(stmt.body)
        self._in_loop -= 1

    def _visit_expression(self, expr: Any) -> None:
        if expr is None:
            return
        if isinstance(expr, IdentifierExpression):
            if self.symbols.lookup(expr.name) is None:
                self.diagnostics.append(SemanticError(
                    message=f"Undefined symbol '{expr.name}'",
                    code="E008",
                    location=_loc(expr),
                ))
        elif isinstance(expr, CallExpression):
            self._visit_expression(expr.callee)
            for arg in expr.arguments:
                self._visit_expression(arg)
        elif isinstance(expr, CallExpression):
            self._visit_expression(expr.callee)
            for arg in expr.arguments:
                self._visit_expression(arg)
        elif isinstance(expr, MemberExpression):
            self._visit_expression(expr.object)
            # If object is a known module import, validate the property exists
            if isinstance(expr.object, IdentifierExpression):
                module_name = expr.object.name
                # Check if it's a registered module
                symbol = self.symbols.lookup(module_name)
                if symbol is not None and symbol.kind == SymbolKind.MODULE:
                    # Module is known, we could validate the property exists
                    # For now, just trust the module is valid - runtime will catch errors
                    pass
        elif isinstance(expr, IndexExpression):
            self._visit_expression(expr.object)
            self._visit_expression(expr.index)
        elif isinstance(expr, FunctionLiteral):
            # Enter function scope
            self.symbols.enter_scope()
            for param in expr.params:
                self.symbols.declare(param, SymbolKind.PARAMETER, _loc(expr))
            # Visit function body
            for stmt in (expr.body or BlockNode()).statements:
                self._visit_statement(stmt)
            self.symbols.exit_scope()
        elif isinstance(expr, ArrayLiteral):
            for item in expr.items:
                self._visit_expression(item)
        elif isinstance(expr, ObjectLiteral):
            for _, val in expr.entries:
                self._visit_expression(val)
        elif hasattr(expr, "left"):
            self._visit_expression(expr.left)
            self._visit_expression(expr.right)
        elif hasattr(expr, "operand"):
            self._visit_expression(expr.operand)
        elif hasattr(expr, "expression"):
            self._visit_expression(expr.expression)


def _loc(node: Any) -> Any:
    return getattr(node, "location", None)


def analyze(node: ASTNode) -> list[SemanticDiagnostic]:
    analyzer = SemanticAnalyzer()
    if isinstance(node, ProgramNode):
        for item in node.body:
            if hasattr(item, "body") and isinstance(item.body, BlockNode):
                analyzer._visit_block(item.body)
            elif isinstance(item, BlockNode):
                for s in item.statements:
                    analyzer._visit_statement(s)
    elif isinstance(node, BlockNode):
        for s in node.statements:
            analyzer._visit_statement(s)
    else:
        analyzer.analyze(node)
    return analyzer.diagnostics
