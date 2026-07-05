# V1.1.6 Type System Execution Trace

> Exact type-checking path per public CLI command.
> Created during P4 repair program.

---

## `panther run file.pan`

1. `cli/panther_cli.py:_run()` → `compiler.runtime.execute_source()`
2. `execute_source()` lexes, parses, creates `StatementExecutor` (NO type checker)
3. `ExpressionEvaluator` handles `+`, comparison, etc. with runtime type checks
4. **Static type checking**: NONE
5. **Runtime type errors**: PT001 (binary ops), PT002 (comparisons)
6. **Archived**: PT001/PT002 fire during expression evaluation, raise `EvaluationError`

**Type checking used**: `compiler/runtime/expression_evaluator.py` (runtime, dynamic)
**NOT used**: `compiler/types/` TypeChecker, `compiler/semantic/` SemanticAnalyzer

## `panther check file.pan`

1. `cli/panther_cli.py:_check()` → lex → parse → `compiler.semantic.analyze()`
2. `SemanticAnalyzer` creates `TypeChecker` from `compiler/types/checker.py`
3. Type checking runs on variable declarations, assignments, function declarations
4. **Static type errors**: T001
5. **Runtime type checks**: NOT run (no evaluation)

**Type checking used**: `compiler/types/checker.py` via `compiler/semantic/`
**NOT used**: `compiler/runtime/expression_evaluator.py`

## `panther build file.pan`

1. `cli/panther_cli.py:_build()` → `_run_as_artifact()` → `execute_source()` (same as `run`)
2. Captures output as shell artifact
3. Same type checking as `run` (runtime only)

## `python -m cli.panther_cli` (formal CLI)

Same as `panther` wrapper — delegates to `cli/panther_cli.py`.

## `python -m cli.panther_cli_v2` (Phase 6 CLI)

Uses `compiler/pipeline/panther_compiler.py` which has its own validation pipeline.

## Key Discovery: Dual Type System

`panther check` and `panther run` use DIFFERENT type enforcement:

| Aspect | `panther check` | `panther run` |
|--------|-----------------|---------------|
| Type checker | `compiler/types/checker.py` | `compiler/runtime/expression_evaluator.py` |
| Error codes | T001 | PT001, PT002 |
| Scope | Static analysis | Runtime evaluation |
| Covers | Variable declarations, assignments, function sigs | Binary ops, comparisons |
| Overlap? | Minimal (different triggers, different error codes) | |

**Consequence**: Code can pass `check` but fail `run`, and vice versa.
Example: A type-annotated assignment mismatch is caught by `check` (T001) but NOT by `run`.
Example: A null comparison type mismatch is caught by `run` (PT002) but NOT by `check`.
