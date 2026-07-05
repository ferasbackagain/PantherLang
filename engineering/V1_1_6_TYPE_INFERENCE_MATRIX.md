# V1.1.6 Type Inference Matrix

> Proven type inference behavior for all literal and expression forms.
> Created during P4 repair program.

## Primitive Literals

| Source | Static Type | Runtime Type | Diagnostic | Proven Test |
|--------|-------------|--------------|------------|-------------|
| `42` | `int` | `int` | None | `test_infer_number_literal` |
| `3.14` | `float` | `float` | None | `test_infer_float_literal` |
| `"hello"` | `string` | `string` | None | `test_infer_string_literal` |
| `true` / `false` | `bool` | `bool` | None | `test_infer_boolean_literal` |
| `null` | `null` | `null` | None | `test_infer_null_literal` |

## Variables

| Source | Static Type | Runtime Type | Diagnostic | Proven Test |
|--------|-------------|--------------|------------|-------------|
| `let x = 42` | `int` (inferred) | `int` | None | `test_check_variable_untyped_declaration` |
| `let x: int = 42` | `int` (annotated) | `int` | None | `test_check_variable_typed_declaration_valid` |
| `let x: int = "hello"` | `int` (annotated) | `string` | **T001** | `test_check_variable_typed_declaration_mismatch` |
| `let x: float = 42` | `float` (annotated) | `int` | None (coercion) | `test_check_variable_typed_declaration_int_to_float` |

## Binary Operations

| Expression | Static Type | Runtime Type | Diagnostic | Proven Test |
|------------|-------------|--------------|------------|-------------|
| `1 + 2` | `int` | `int` | None | `test_infer_binary_addition` |
| `1.5 + 2.5` | `float` | `float` | None | `test_get_common_type_int_float` |
| `1 + 2.5` | `float` | `float` | None | `test_get_common_type_int_float` |
| `"a" + "b"` | `string` | `string` | None | `test_semantic_typed_assignment_valid` (string concat) |
| `true && false` | `bool` | `bool` | None | `test_infer_binary_comparison` |
| `1 == 2` | `bool` | `bool` | None | `test_infer_binary_comparison` |
| `1 > 2` | `bool` | `bool` | None | `test_infer_binary_comparison` |
| `1 + "hello"` | `any` | `error` | **PT001** (runtime) | `test_type_error_on_bool_arithmetic` |

## Comparison Operations (Runtime)

| Expression | Runtime Result | Error Code |
|------------|----------------|------------|
| `5 == null` | `false` | None (null == any allowed) |
| `5 != null` | `true` | None (null != any allowed) |
| `5 > null` | Runtime error | **PT002** |
| `null > 5` | Runtime error | **PT002** |
| `5 < "hello"` | Runtime error | **PT002** |
| `true == 1` | Runtime error | **PT002** |

## Collections (Arrays/Objects)

| Source | Static Type | Runtime Type | Diagnostic | Notes |
|--------|-------------|--------------|------------|-------|
| `[1, 2, 3]` | `any` | `array` | None | No ArrayType in static checker |
| `["a", "b"]` | `any` | `array` | None | No element type tracking |
| `[1, "hello"]` | `any` | `array` | None | Mixed types allowed at runtime |
| `[]` | `any` | `array` | None | Empty array |
| `[[1, 2], [3, 4]]` | `any` | `array` | None | Nested arrays |
| `{x: 1, y: 2}` | `any` | `object` | None | No ObjectType in static checker |
| `{x: 1, y: "hello"}` | `any` | `object` | None | Mixed value types allowed |
| `{}` | `any` | `object` | None | Empty object |

## Member Access & Indexing

| Expression | Static Type | Runtime Type | Diagnostic |
|------------|-------------|--------------|------------|
| `obj.x` | `any` | Depends on value | None (static) |
| `arr[0]` | `any` | Depends on value | None (static) |
| `obj["key"]` | `any` | Depends on value | None (static) |

## Functions

| Source | Static Return Type | Runtime Return Type | Diagnostic |
|--------|-------------------|---------------------|------------|
| `fn add(a, b) { a + b }` | `any` (no annotation) | `int` / `float` / `string` | None |
| `fn add(a: int, b: int): int { a + b }` | `int` | `int` | None |
| `fn add(a: int, b: int): int { "hello" }` | `int` (expected) | `string` | **T001** (static) |
| `fn get(): null { null }` | `null` | `null` | None |
| Recursive functions | Supported | Supported | None |

## Variable Reassignment

| Scenario | Static Check | Runtime |
|----------|--------------|---------|
| `let x: int = 1; x = 2` | OK | OK |
| `let x: int = 1; x = "hello"` | **T001** | No check (runtime allows) |
| `let x = 1; x = "hello"` | OK (untyped) | OK (runtime allows) |

## Type Coercion Rules (Static)

| From \ To | `int` | `float` | `string` | `bool` | `null` | `any` |
|-----------|-------|---------|----------|--------|--------|-------|
| `int` | ✓ | ✓ | ✗ | ✗ | ✗ | ✓ |
| `float` | ✗ | ✓ | ✗ | ✗ | ✗ | ✓ |
| `string` | ✗ | ✗ | ✓ | ✗ | ✗ | ✓ |
| `bool` | ✗ | ✗ | ✗ | ✓ | ✗ | ✓ |
| `null` | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| `any` | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## Key Findings

1. **No ArrayType/ObjectType in static checker** - All collections infer to `AnyType`
2. **No FunctionType in static checker** - Function return types only checked when annotated
3. **No StructType/EnumType/TraitType** - AST nodes exist but no static type representation
4. **Dual type system** - Static (T001) and Runtime (PT001/PT002) use different rules
5. **Null comparisons** - `==` and `!=` allow null with any type; ordering operators require matching types

## Test Coverage

All tests in `tests/phase4_batch4_1/` pass:
- `test_type_system.py` - Core type system tests
- `test_type_annotations.py` - Type annotation and inference tests
- `test_type_inference_truth.py` - P4 truth verification tests