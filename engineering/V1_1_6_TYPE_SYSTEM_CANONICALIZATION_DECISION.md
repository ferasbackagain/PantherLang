# V1.1.6 Type System Canonicalization Decision

> Strategic decision document for PantherLang type system v1.1.6.
> Created during P4 repair program.

## Executive Summary

PantherLang v1.1.6 has **two separate, incompatible type systems** that are both active in production:
1. **Static type checker** (`compiler/types/`) - used by `panther check`
2. **Runtime type checker** (`compiler/runtime/expression_evaluator.py`) - used by `panther run`/`build`

These systems have different type representations, different error codes, and different coverage. Code can pass `check` but fail at `run` time, and vice versa.

---

## 1. Canonical Active Type Checker

**For `panther check`**: `compiler/types/checker.py` — `TypeChecker` class
- **Error code**: T001
- **Scope**: Variable declarations, assignments, function signatures
- **Types**: IntType, FloatType, StringType, BoolType, NullType, AnyType
- **Missing**: ArrayType, ObjectType, FunctionType, StructType, EnumType, TraitType, OptionalType

**For `panther run`/`build`**: `compiler/runtime/expression_evaluator.py` — runtime evaluation
- **Error codes**: PT001 (binary ops), PT002 (comparisons)
- **Scope**: Binary operations, comparison operations
- **Types**: Dynamic runtime types (int, float, string, bool, null, array, object)

**These are NOT unified. There is no single canonical type checker.**

---

## 2. Secondary Type Systems

| System | Location | Used By | Status |
|--------|----------|---------|--------|
| Semantic types (PantherType) | `compiler/core/semantic_types.py` | `language/panther.py` (legacy CLI) | LEGACY_ACTIVE |
| Model type checker | `compiler/core/type_checker.py` | `language/panther.py` (legacy CLI) | LEGACY_ACTIVE |
| Phase 6 pipeline | `compiler/pipeline/panther_compiler.py` | `panther_cli_v2` (experimental) | LEGACY_ACTIVE |
| Advanced inference | `language/compiler/type_inference/` | None (standalone) | EXPERIMENTAL |
| Static analysis | `language/types/static_analysis/` | None (standalone) | EXPERIMENTAL |

---

## 3. Legacy Systems

**`compiler/core/`** — Legacy v0.5 type system
- Used by: `language/panther.py` (separate CLI entry point)
- Types: PantherType with nullable, generic_args
- 24 builtin type names
- NOT used by main `panther` CLI

**`language/compiler/core/`** — Exact duplicate of above
- Used by: `language/tests/test_phase1_models.py` only
- LEGACY_UNUSED

**`compiler/pipeline/`** — Phase 6 compiler
- No dedicated TypeChecker
- Structural validation only
- Error codes: PANTHER-FN-001

---

## 4. Public Command Type Paths

| Command | Type Checker | Static Errors | Runtime Errors |
|---------|-------------|---------------|----------------|
| `panther check` | `compiler/types/checker.py` | T001, E001-E008, S001-S005 | NONE |
| `panther run` | `compiler/runtime/expression_evaluator.py` | NONE | PT001, PT002 |
| `panther build` | Same as `run` | NONE | PT001, PT002 |
| `panther_cli_v2` | `compiler/pipeline/panther_compiler.py` | PANTHER-FN-001 | N/A |

---

## 5. Repaired in v1.1.6

1. **Runtime comparison type safety (PT002)** - Fixed in `expression_evaluator.py`
   - Null comparable with any type for `==`/`!=`
   - Numeric (int/float) comparable with each other
   - Same type comparable
   - All other combinations → PT002

2. **Static null type annotation** - Works correctly in `compiler/types/checker.py`
   - `let x: null = null` accepted
   - `let x: int = null` → T001

3. **Unknown explicit type name** - Produces T001 diagnostic
   - `let x: UnknownType = 5` → T001 "Unknown type 'UnknownType'"

4. **Int to float coercion** - Allowed in static checker
   - `let x: float = 42` accepted

5. **Float to int coercion** - Rejected in static checker
   - `let x: int = 3.14` → T001

---

## 6. Remaining Partial in v1.1.6

| Feature | Static | Runtime | Status |
|---------|--------|---------|--------|
| ArrayType | ✗ | array | MISSING |
| ObjectType | ✗ | object | MISSING |
| FunctionType | ✗ | callable | MISSING |
| StructType | AST only | dict with `__type` | PARTIAL |
| EnumType | AST only | NONE | PARSE_ONLY |
| TraitType | AST only | NONE | PARSE_ONLY |
| OptionalType | ✗ | NONE | MISSING |
| Nullable syntax (`int?`) | AST only (field_type) | NONE | PARSE_ONLY |
| Field type validation | ✗ | ✗ | MISSING |
| Generic types | ✗ | ✗ | MISSING |

---

## 7. Deferred to v1.2

**Must not be claimed in v1.1.6:**

1. **Complete struct type system** - No static field validation, no StructType
2. **Complete enum type system** - No runtime values, no EnumType
3. **Trait system** - No implementation syntax, no conformance checking
4. **Collection types** - No ArrayType/ObjectType, no element tracking
5. **Function types** - No FunctionType, no first-class functions
6. **Unified static + runtime type story** - Two separate systems exist
7. **Nullable types (`T?`)** - Syntax parsed but not represented in type system
8. **Generics** - Not implemented
9. **Exhaustiveness checking** - Not implemented

---

## 8. Migration Path Recommended

### Phase 1 (v1.2): Unify Type Representation
- Define `ArrayType(element_type)`, `ObjectType(fields)`, `FunctionType(params, return)`
- Add `StructType(fields)`, `EnumType(variants)`, `OptionalType(inner)`
- Make static checker use same type representations as runtime

### Phase 2 (v1.2+): Runtime Type Enforcement
- Add optional runtime type checking for function calls
- Add struct field type validation at construction
- Add array element type checking (optional, opt-in)

### Phase 3 (v1.3): Advanced Features
- Generics with monomorphization
- Trait system with conformance checking
- Exhaustiveness checking for enums
- Nullable type syntax (`T?`) with proper representation

---

## 9. What Must Never Be Claimed in v1.1.6

- ❌ "PantherLang has struct types" — Only AST + runtime dicts
- ❌ "PantherLang has enum types" — Only AST declarations
- ❌ "PantherLang has trait types" — Only AST declarations
- ❌ "PantherLang has array/object types" — Only AnyType wrappers
- ❌ "PantherLang has function types" — Only parameter/return annotations
- ❌ "Type checking is unified" — Two separate systems
- ❌ "Nullable types are supported" — Syntax only, no representation
- ❌ "Generics are supported" — Not implemented

---

## 10. Testing Requirements

All v1.1.6 type system tests must:
- Test T001 static diagnostics (via `panther check` / SemanticAnalyzer)
- Test PT001/PT002 runtime diagnostics (via `panther run`)
- Document which system catches which error
- NOT claim coverage for missing type representations

Current baseline: **1084 tests pass** (includes new P4 truth tests)