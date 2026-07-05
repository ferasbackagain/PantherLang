# V1.1.6 Type Diagnostic Matrix

> Error code documentation and mapping.
> Created during P4 repair program.

## Diagnostic Codes Overview

| Code | Layer | Where | Pipeline | Meaning |
|------|-------|-------|----------|----------|
| T001 | Compile-time type | `compiler/types/checker.py:194` | `panther check` | Generic type mismatch error |
| PT001 | Runtime type (add/binary) | `compiler/runtime/expression_evaluator.py:300,315` | `panther run` | Numeric operation type mismatch |
| PT002 | Runtime type (comparison) | `compiler/runtime/expression_evaluator.py:67,92,101,282` | `panther run` | Comparison type mismatch |
| E001-E008 | Semantic analysis | `compiler/semantic/analyzer.py` | `panther check` | Semantic validation errors |
| S001-S005 | Security analysis | `compiler/security/analyzer.py` | `panther check` | Security validation errors |

## T001 Diagnostic Details

### Triggers
- Type annotations mismatch (variable declarations)
- Function parameter/return type mismatches
- Assignment to typed variables
- Binary operation operand type mismatches (static)
- Function call argument mismatch

### Source Location
- `compiler/types/checker.py:194` - Variable declaration checks
- Various in `compiler/types/checker.py` methods

### CLI Behavior
- Collected by `SemanticAnalyzer`
- Reported through `cli/panther_cli.py:_check()`
- Printed in `[SEMANTIC]` format to stderr

### Runtime Behavior
- NOT CHECKED by `run`
- Runtime uses PT001/PT002 instead

## PT001 Diagnostic Details

### Triggers
- Binary operations (`+`, `-`, `*`, `/`, `%`, `**`) with incompatible operand types
- Logic errors where types are not numeric

### Source Location
- `compiler/runtime/expression_evaluator.py:300` - Binary evaluation
- `compiler/runtime/expression_evaluator.py:315` - Addition evaluation

### CLI Behavior
- Fired during execution in `expression_evaluator.py`
- Reported as `EvaluationError` with PT001 prefix
- Only occurs during `panther run`

### Runtime Behavior
- `EvaluationError` raised with detailed message
- Execution stops

## PT002 Diagnostic Details

### Triggers
- Comparison operators (`==`, `!=`, `>`, `<`, `>=`, `<=`) with incompatible operand types
- Null comparisons are special-cased (allowed for equality only)

### Source Location
- `compiler/runtime/expression_evaluator.py:67` - `_panther_comparable_types`
- `compiler/runtime/expression_evaluator.py:92` - `_panther_require_comparison_compatible`
- `compiler/runtime/expression_evaluator.py:101` - `_panther_require_comparison_compatible`
- `compiler/runtime/expression_evaluator.py:282` - Comparison error path

### CLI Behavior
- Fired during execution in `expression_evaluator.py`
- Reported as `EvaluationError` with PT002 prefix
- Only occurs during `panther run`

### Runtime Behavior
- `EvaluationError` raised with detailed message
- Execution stops

## Backward Compatibility Notes

### T001 Overloading
- T001 covers ALL type mismatches in the static checker
- This includes binary operation type mismatches, which are checked at parse-time by runtime evaluator at run-time via PT001
- This creates gaps in error coverage

### Error Code Consistency
- T001: Compile-time type checking
- PT001: Runtime binary operation type checking
- PT002: Runtime comparison type checking
- E001-E008: Semantic analysis (not type-related)
- S001-S005: Security analysis (not type-related)

## Recommendations

1. **Keep current architecture** - Dual type systems (check vs run) are currently in production
2. **Document discrepancies** - Clearly communicate that type checking is split
3. **Fix S002 upstream** - Unknown explicit type names issue
4. **Update error code matrix** - Add new PT codes as they're discovered
5. **Maintain diagnostic consistency** - Don't renumber historical diagnostics

Note: PT prefix codes are new in v1.1.6 and were not present in v1.1.5 and earlier.
