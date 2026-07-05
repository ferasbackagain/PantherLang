# V1.1.6 Type System Implementation Map

> Forensic inventory of every type-related implementation.
> Created during P4 repair program.

## Classification Legend

| Classification | Meaning |
|---------------|---------|
| CANONICAL_ACTIVE | Used by public `panther run/check` |
| ACTIVE_SECONDARY | Used by some pipeline but not primary |
| LEGACY_ACTIVE | Still used by some code path |
| LEGACY_UNUSED | Exists but not imported by production code |
| EXPERIMENTAL | Standalone, not wired into any CLI |

---

## 1. CANONICAL_ACTIVE — `compiler/types/`

This is the compile-time type checker used by `panther check` via the SemanticAnalyzer.

### `compiler/types/types.py`

**Type classes defined:**
- `TypeBase(frozen dataclass)` — base type with `name` field
- `IntType = TypeBase("int")` — singleton
- `FloatType = TypeBase("float")` — singleton
- `StringType = TypeBase("string")` — singleton
- `BoolType = TypeBase("bool")` — singleton
- `NullType = TypeBase("null")` — singleton
- `AnyType = TypeBase("any")` — singleton

**No ArrayType, ObjectType, FunctionType, StructType, EnumType, TraitType, OptionalType.**

All collections (arrays, objects), member expressions, index expressions → `AnyType`.

**Functions:**
- `is_assignable(value_type, target_type)` — assignability rules
- `get_common_type(left, right)` — binary op type unification

### `compiler/types/checker.py`

- `TypeChecker` class — creates `._env` dict for declared types
- Key methods: `resolve_type_name`, `infer_type`, `declare`, `check_variable_declaration`, `check_assignment`, `check_function_declaration`
- Error code: **T001** for all type mismatches

### Pipeline

```
panther check → SemanticAnalyzer → TypeChecker → T001
```

---

## 2. CANONICAL_ACTIVE — `compiler/runtime/expression_evaluator.py`

Runtime type enforcement used by `panther run`.

- `_panther_runtime_type_name(value)` — Python value → Panther type name string
- `_panther_require_comparison_compatible(operator, left, right)` — **PT002**
- `_panther_comparable_types(left, right)` — which types can be compared
- `_panther_compare_values(op, left, right)` — value comparison with type enforcement

**Error codes:**
- **PT001** — type mismatch in `+` or binary ops
- **PT002** — comparison type mismatch

Pipeline:
```
panther run → execute_source → ExpressionEvaluator → PT001/PT002
```

---

## 3. LEGACY_ACTIVE — `compiler/core/`

### `compiler/core/semantic_types.py`

- `PantherType(name, nullable, generic_args)` — frozen dataclass
- 24 builtin type names (15 primitive + 5 collection + 4 advanced)
- `is_builtin_type(type_name)`, `parse_type(type_name)`

Used by `language/panther.py` (v0.5 CLI, separate from main CLI).

### `compiler/core/type_checker.py`

- Different `TypeChecker` class — model-level field validation
- `check_field_type`, `check_model`

### `compiler/core/semantic_engine.py`

- `SemanticEngine` — duplicate fields + type validation
- Legacy pipeline: `language/panther.py`

---

## 4. LEGACY_ACTIVE — `compiler/pipeline/panther_compiler.py`

Phase 6 pipeline. No dedicated TypeChecker — does structural validation only.
Error codes: `PANTHER-FN-001`, not T/PT.

---

## 5. LEGACY_UNUSED — `language/compiler/core/`

Exact duplicates of `compiler/core/*` files. Only imported by `language/tests/test_phase1_models.py`.

---

## 6. EXPERIMENTAL — `language/compiler/type_inference/`

`AdvancedTypeInferenceEngine` with its own `PantherType` class.
Monomorphization with Union support. Error codes: `PANTHER-TYPE-064-*`.
Standalone — never wired into any CLI.

---

## 7. EXPERIMENTAL — `language/types/static_analysis/type_analyzer.py`

`PantherTypeAnalyzer` with string-based types.
Error codes: `PANTHER-TYPE-001`. Standalone.

---

## Error Code Summary

| Code | Layer | Where | Pipeline |
|------|-------|-------|----------|
| T001 | Compile-time type | `compiler/types/checker.py:194` | `panther check` |
| PT001 | Runtime type (add/binary) | `compiler/runtime/expression_evaluator.py:300,315` | `panther run` |
| PT002 | Runtime type (comparison) | `compiler/runtime/expression_evaluator.py:67,92,101,282` | `panther run` |
| E001-E008 | Semantic analysis | `compiler/semantic/analyzer.py` | `panther check` |
| S001-S005 | Security analysis | `compiler/security/analyzer.py` | `panther check` |
| PANTHER-TYPE-064-* | Phase 6.4 experimental | `language/compiler/type_inference/` | None |
| PANTHER-TYPE-001 | Phase 5.2 experimental | `language/types/static_analysis/` | None |

## Key Architectural Insight

**`panther check` and `panther run` use DIFFERENT type systems:**
- `check` uses `compiler/types/checker.py` (TypeChecker, static, T001)
- `run` uses `compiler/runtime/expression_evaluator.py` (runtime checks, PT001/PT002)

This means code can pass `check` but fail at `run` time, and vice versa.
There is NO unified static + runtime type story.
