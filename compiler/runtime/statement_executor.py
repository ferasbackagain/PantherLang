from __future__ import annotations

# PANTHER_COMPARISON_RUNTIME_FIX1_V2_START
from __future__ import annotations
def _panther_type_name(value):
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int) and not isinstance(value, bool):
        return "int"
    if isinstance(value, float):
        return "float"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    if value is None:
        return "null"
    return type(value).__name__


def _panther_str(value) -> str:
    """Convert a value to its PantherLang string representation."""
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return "null"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return value
    if isinstance(value, list):
        items = ", ".join(_panther_str(item) for item in value)
        return f"[{items}]"
    if isinstance(value, dict):
        # Skip __type key if present (used for struct instances)
        items = []
        for k, v in value.items():
            if k == "__type":
                continue
            items.append(f"{k}: {_panther_str(v)}")
        return f"{{{', '.join(items)}}}"
    return str(value)


def _panther_comparable_types(left, right):
    left_type = _panther_type_name(left)
    right_type = _panther_type_name(right)
    
    # null is comparable with any type for equality operators.
    if left_type == "null" or right_type == "null":
        return
    
    # Numeric comparisons allow int/float combinations, but not bool.
    numeric = {"int", "float"}
    if left_type in numeric and right_type in numeric:
        return
    
    # Same runtime type is comparable.
    if left_type == right_type:
        return
    
    raise RuntimeError(
        "Panther Type Error PT002: Cannot compare values of different types. "
        f"Operator '?' cannot be applied to {left_type} and {right_type}. "
        "PantherLang does not perform implicit comparison conversion. "
        "Use to_string(), to_int(), to_float(), to_number(), or to_bool() explicitly."
    )


def _panther_comparison_error(op, left, right):
    return RuntimeError(
        "Panther Type Error PT002: Cannot compare values of different types. "
        f"Operator '{op}' cannot be applied to "
        f"{_panther_type_name(left)} and {_panther_type_name(right)}. "
        "PantherLang does not perform implicit comparison conversion. "
        "Use to_string(), to_int(), to_float(), to_number(), or to_bool() explicitly."
    )


def _panther_compare_values(op, left, right):
    _panther_comparable_types(left, right)
    if op == "==":
        return left == right
    if op == "!=":
        return left != right
    if op == ">":
        return left > right
    if op == "<":
        return left < right
    if op == ">=":
        return left >= right
    if op == "<=":
        return left <= right
    raise RuntimeError(f"Unsupported comparison operator: {op}")
# PANTHER_COMPARISON_RUNTIME_FIX1_V2_END


from dataclasses import dataclass, field
from typing import Any

from compiler.ast import (
    AssignmentStatement,
    BlockNode,
    BreakStatement,
    ContinueStatement,
    ElifBranch,
    EnumDeclaration,
    ExpressionStatement,
    ForStatement,
    FunctionDeclaration,
    IdentifierExpression,
    IfStatement,
    ImportStatement,
    LoopStatement,
    PrintStatement,
    ReturnStatement,
    RouteStatement,
    Statement,
    StructDeclaration,
    TraitDeclaration,
    VariableDeclaration,
    WhileStatement,
)

from .expression_evaluator import EvaluationError, ExpressionEvaluator
from .variable_environment import VariableEnvironment


class LoopControlException(Exception):
    pass


class BreakException(LoopControlException):
    pass


class ContinueException(LoopControlException):
    pass


@dataclass
class ExecutionResult:
    captured_output: list[str] = field(default_factory=list)
    return_value: Any = None
    error: str | None = None


class StatementExecutor:
    def __init__(self, environment: VariableEnvironment | None = None, http_server: Any = None) -> None:
        self._env = environment or VariableEnvironment()
        self._evaluator = ExpressionEvaluator(self._env)
        self._output: list[str] = []
        self._http_server = http_server

    @property
    def environment(self) -> VariableEnvironment:
        return self._env

    @property
    def output(self) -> list[str]:
        return list(self._output)

    def make_function(self, decl: FunctionDeclaration) -> Any:
        def _fn(*args: Any) -> Any:
            child_env = self._env._new_child()
            child_env._functions = dict(self._env._functions)
            for param, arg in zip(decl.params, args):
                child_env._variables[param] = arg
            child_exec = StatementExecutor(child_env)
            for s in decl.body.statements:
                before = len(child_exec._output)
                result = child_exec.execute(s)
                after = len(child_exec._output)
                self._output.extend(child_exec._output[before:after])
                if result.return_value is not None:
                    return result.return_value
                if result.error is not None:
                    raise EvaluationError(result.error)
            return None
        return _fn

    def execute(self, stmt: Statement) -> ExecutionResult:
        try:
            if isinstance(stmt, VariableDeclaration):
                self._execute_variable_declaration(stmt)
            elif isinstance(stmt, ImportStatement):
                self._execute_import(stmt)
            elif isinstance(stmt, StructDeclaration):
                self._execute_struct_declaration(stmt)
            elif isinstance(stmt, EnumDeclaration):
                self._execute_enum_declaration(stmt)
            elif isinstance(stmt, TraitDeclaration):
                self._execute_trait_declaration(stmt)
            elif isinstance(stmt, FunctionDeclaration):
                self._execute_function_declaration(stmt)
            elif isinstance(stmt, AssignmentStatement):
                self._execute_assignment(stmt)
            elif isinstance(stmt, PrintStatement):
                self._execute_print(stmt)
            elif isinstance(stmt, ExpressionStatement):
                self._execute_expression(stmt)
            elif isinstance(stmt, BlockNode):
                self._execute_block(stmt)
            elif isinstance(stmt, IfStatement):
                result = self._execute_if(stmt)
                if result.return_value is not None:
                    return result
            elif isinstance(stmt, LoopStatement):
                result = self._execute_loop(stmt)
                if result.return_value is not None:
                    return result
            elif isinstance(stmt, WhileStatement):
                result = self._execute_while(stmt)
                if result.return_value is not None:
                    return result
            elif isinstance(stmt, ForStatement):
                result = self._execute_for(stmt)
                if result.return_value is not None:
                    return result
            elif isinstance(stmt, RouteStatement):
                self._execute_route(stmt)
            elif isinstance(stmt, BreakStatement):
                raise BreakException()
            elif isinstance(stmt, ContinueStatement):
                raise ContinueException()
            elif isinstance(stmt, ReturnStatement):
                return ExecutionResult(
                    captured_output=list(self._output),
                    return_value=self._evaluator.evaluate(stmt.expression),
                )
            else:
                return ExecutionResult(
                    captured_output=list(self._output),
                    error=f"Unsupported statement: {type(stmt).__name__}",
                )
        except LoopControlException:
            raise
        except Exception as exc:
            return ExecutionResult(
                captured_output=list(self._output),
                error=str(exc),
            )
        return ExecutionResult(captured_output=list(self._output))

    def run(self, statements: list[Statement]) -> ExecutionResult:
        for stmt in statements:
            try:
                result = self.execute(stmt)
            except LoopControlException as exc:
                return ExecutionResult(
                    captured_output=list(self._output),
                    error=f"Cannot use {type(exc).__name__.replace('Exception', '').lower()} outside a loop",
                )
            if result.error is not None:
                return result
            if result.return_value is not None:
                return result
        return ExecutionResult(captured_output=list(self._output))

    def _execute_variable_declaration(self, stmt: VariableDeclaration) -> None:
        value = self._evaluator.evaluate(stmt.initializer) if stmt.initializer else None
        self._env.define(stmt.name, value)

    def _execute_import(self, stmt: ImportStatement) -> None:
        var_name = stmt.alias if stmt.alias else stmt.module_name.split(".")[0]
        module_obj = {"__module": stmt.module_name}
        try:
            self._env.define(var_name, module_obj)
        except Exception:
            pass

    def _execute_struct_declaration(self, stmt: StructDeclaration) -> None:
        self._env.define_type(stmt.name, stmt)

    def _execute_enum_declaration(self, stmt: EnumDeclaration) -> None:
        self._env.define_type(stmt.name, stmt)

    def _execute_trait_declaration(self, stmt: TraitDeclaration) -> None:
        pass

    def _execute_function_declaration(self, stmt: FunctionDeclaration) -> None:
        self._env.define_function(stmt.name, self.make_function(stmt))

    def _execute_assignment(self, stmt: AssignmentStatement) -> None:
        value = self._evaluator.evaluate(stmt.value)
        if stmt.operator != "=":
            target_name = stmt.target.name if isinstance(stmt.target, IdentifierExpression) else None
            if target_name is not None:
                current = self._env.lookup(target_name)
                op = stmt.operator
                if op == "+=":
                    value = current + value
                elif op == "-=":
                    value = current - value
                elif op == "*=":
                    value = current * value
                elif op == "/=":
                    value = current // value if isinstance(current, int) and isinstance(value, int) else current / value
                elif op == "%=":
                    value = current % value
        if isinstance(stmt.target, IdentifierExpression):
            self._env.assign(stmt.target.name, value)
        else:
            self._evaluator.evaluate(stmt.target)
            raise RuntimeError("Complex assignment targets not supported")

    def _execute_print(self, stmt: PrintStatement) -> None:
        value = self._evaluator.evaluate(stmt.expression) if stmt.expression else None
        self._output.append(_panther_str(value))

    def _execute_expression(self, stmt: ExpressionStatement) -> None:
        self._evaluator.evaluate(stmt.expression)

    def _execute_block(self, stmt: BlockNode) -> None:
        child_env = self._env._new_child()
        child_exec = StatementExecutor(child_env)
        for s in stmt.statements:
            before = len(child_exec._output)
            result = child_exec.execute(s)
            after = len(child_exec._output)
            self._output.extend(child_exec._output[before:after])
            if result.error is not None:
                raise EvaluationError(result.error)
            if result.return_value is not None:
                raise EvaluationError("Return statement outside function")

    def _execute_if(self, stmt: IfStatement) -> ExecutionResult:
        condition = self._evaluator.evaluate(stmt.condition)
        if condition:
            return self._execute_block_and_return(stmt.then_block)
        for branch in stmt.elif_branches:
            elif_cond = self._evaluator.evaluate(branch.condition)
            if elif_cond:
                return self._execute_block_and_return(branch.body)
        if stmt.else_block:
            return self._execute_block_and_return(stmt.else_block)
        return ExecutionResult(captured_output=list(self._output))

    def _execute_block_and_return(self, block: BlockNode) -> ExecutionResult:
        child_env = self._env._new_child()
        child_exec = StatementExecutor(child_env)
        for s in block.statements:
            before = len(child_exec._output)
            result = child_exec.execute(s)
            after = len(child_exec._output)
            self._output.extend(child_exec._output[before:after])
            if result.error is not None:
                return result
            if result.return_value is not None:
                return result
        return ExecutionResult(captured_output=list(self._output))

    def _execute_loop(self, stmt: LoopStatement) -> ExecutionResult:
        while True:
            try:
                result = self._execute_block_and_return(stmt.body)
                if result.error is not None:
                    return result
                if result.return_value is not None:
                    return result
            except BreakException:
                break
            except ContinueException:
                continue
        return ExecutionResult(captured_output=list(self._output))

    def _execute_while(self, stmt: WhileStatement) -> ExecutionResult:
        while self._evaluator.evaluate(stmt.condition):
            try:
                result = self._execute_block_and_return(stmt.body)
                if result.error is not None:
                    return result
                if result.return_value is not None:
                    return result
            except BreakException:
                break
            except ContinueException:
                continue
        return ExecutionResult(captured_output=list(self._output))

    def _execute_for(self, stmt: ForStatement) -> ExecutionResult:
        start_val = self._evaluator.evaluate(stmt.start) if stmt.start else 0
        end_val = self._evaluator.evaluate(stmt.end) if stmt.end else 0
        step_val = self._evaluator.evaluate(stmt.step) if stmt.step else 1
        i = start_val
        if not isinstance(start_val, int | float) or not isinstance(end_val, int | float):
            return ExecutionResult(
                captured_output=list(self._output),
                error=f"For loop range requires numeric values, got {type(start_val).__name__}..{type(end_val).__name__}",
            )
        while i <= end_val:
            child_env = self._env._new_child()
            child_env.define(stmt.var, i)
            executor = StatementExecutor(child_env)
            try:
                result = executor._execute_block_and_return(stmt.body)
                self._output.extend(executor._output)
                if result.error is not None:
                    return result
                if result.return_value is not None:
                    return result
            except BreakException:
                break
            except ContinueException:
                i += step_val
                continue
            i += step_val
        return ExecutionResult(captured_output=list(self._output))

    def _execute_route(self, stmt: RouteStatement) -> None:
        if self._http_server:
            handler = lambda **kwargs: self._execute_route_handler(stmt, kwargs)
            self._http_server.router.add_route(stmt.method, stmt.path, handler)
        # Also register in environment for testing/inspection
        route_name = f"__route_{stmt.method}:{stmt.path}"
        self._env.define_function(route_name, lambda **kwargs: self._execute_route_handler(stmt, kwargs))

    def _execute_route_handler(self, stmt: RouteStatement, kwargs: dict) -> Any:
        child_env = self._env._new_child()
        for key, value in kwargs.items():
            child_env._variables[key] = value
        child_exec = StatementExecutor(child_env)
        result = child_exec._execute_block_and_return(stmt.body)
        # Propagate output to parent executor
        self._output.extend(child_exec._output)
        # Return default success response if no explicit return
        if result.return_value is not None:
            return result.return_value
        return {"ok": True}