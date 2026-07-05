# V1.1.6 Function Types Status

> Audit of function type system in PantherLang v1.1.6.
> Created during P4 repair program.

## Static Type Checker (`compiler/types/checker.py`)

**FunctionType**: NOT DEFINED

**Parameter type annotations**: ✓ Parsed and stored in AST
- `FunctionDeclaration.param_types: tuple[str | None, ...]`

**Return type annotation**: ✓ Parsed and stored in AST
- `FunctionDeclaration.return_type: str | None`

**Type checking behavior** (`TypeChecker.check_function_declaration`):
1. Validates parameter types against `_TYPE_NAME_MAP` (int, float, string, bool, null, any)
2. Validates return type against `_TYPE_NAME_MAP`
3. If body has `ReturnStatement`, checks return expression type against declared return type
4. Unknown parameter/return types → **T001** diagnostic

**Function call type checking** (`TypeChecker.infer_type` for `CallExpression`):
- Looks up function in `_functions` dict (name → (param_types, return_type))
- Returns declared return type (resolved via `resolve_type_name`)
- If function not in `_functions` but in `_env`, returns env type
- Otherwise returns `AnyType`

**Function declaration environment** (`TypeChecker.declare_function`):
- Stores function signature in `_functions`
- Adds function name to `_env` with resolved return type

## Runtime (`compiler/runtime/`)

**Function representation**: Python callable (closure)
- Created in `StatementExecutor.make_function`
- Captures environment, executes body statements
- Returns `return_value` from `ReturnStatement`

**Function call**:
- `_eval_call` in `ExpressionEvaluator`
- If callee is a type name (struct), constructs struct instance
- If callee is a function, invokes Python callable with evaluated args

**Parameter/return validation at runtime**: NONE
- No type checking of arguments at call site
- No type checking of return value
- Arguments passed as-is to Python callable

## Closures

- **Parser**: Supports nested functions
- **Static**: Not tested for closure type capture
- **Runtime**: Works via `child_env._functions = dict(self._env._functions)` in `make_function`

## Recursion

- **Runtime**: Works (function defined in env before body executes)
- **Static**: Not specifically tested

## First-class functions

- **Parser**: Function as expression? Not supported (only `FunctionDeclaration` statement)
- **Static**: Function names stored in `_env` as their return type
- **Runtime**: Functions NOT first-class values (can't pass as argument, assign to variable)

## Evidence

```panther
panther main {
    fn add(a: int, b: int): int {
        return a + b;
    }
    let result = add(1, 2);
    print result;  // prints "3"
    
    // Return type mismatch - caught by static checker
    fn bad(): int {
        return "hello";
    }
}
```

## Tests

**Static tests** (`tests/phase4_batch4_1/test_type_annotations.py`):
- `test_fn_type_annotation` - AST has correct annotations
- `test_check_function_declaration_valid` - Valid function type checks
- `test_check_function_declaration_return_mismatch` - Return mismatch → T001
- `test_check_function_declaration_no_return_type` - No return type allowed
- `test_type_checker_infer_call_function` - Call infers return type
- `test_type_checker_infer_call_no_return` - Call with no return type → Any
- `test_semantic_with_type_annotations` - Full semantic + type check
- `test_semantic_fn_return_type_valid` - Valid return type
- `test_semantic_fn_return_type_invalid` - Invalid return type → T001
- `test_fn_with_typed_params_valid_call` - Typed params work
- `test_int_to_float_allowed` - int to float coercion in params
- `test_float_to_int_not_allowed` - float to int rejected in params

## Classification

| Feature | Status |
|---------|--------|
| Parameter type annotations | ✓ Parsed, ✓ Statically checked |
| Return type annotations | ✓ Parsed, ✓ Statically checked |
| FunctionType class | ✗ Not defined |
| Call site argument checking | ✗ Not implemented |
| First-class functions | ✗ Not supported |
| Closure typing | ✗ Not implemented |
| Generic functions | ✗ Not supported |

## Verdict

**Function types are PARTIAL in static checker, NONE at runtime.**
- Parameter and return type annotations work for static checking
- No `FunctionType` representation in type system
- No runtime type enforcement for function calls
- Functions are not first-class values
Do not claim function types are complete in v1.1.6.