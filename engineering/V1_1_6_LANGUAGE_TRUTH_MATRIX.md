# PantherLang v1.1.6 — Language Truth Matrix

**Date:** 2026-07-04

---

## Classification Legend

| Label | Meaning |
|-------|---------|
| ✅ IMPLEMENTED_PROVEN | Works in real execution, test exists |
| ⚠️ IMPLEMENTED_PARTIAL | Works but with documented limitations |
| ❌ IMPLEMENTED_UNPROVEN | Code exists but untested |
| 📝 DOCUMENTED_ONLY | Claimed in docs but not in implementation |
| 🔮 PLANNED | In spec but not implemented |
| 💥 BROKEN | Code exists but doesn't work |
| ❓ CONTRADICTORY | Docs say one thing, code says another |

---

## Lexical Structure

| Feature | Status | Evidence |
|---------|--------|----------|
| Integer literals (`42`) | ✅ | `phase3_language_truth.pan` |
| Float literals (`3.14`) | ✅ | `phase3_language_truth.pan` |
| String literals (`"hello"`) | ✅ | `phase3_language_truth.pan` |
| Boolean literals (`true`, `false`) | ✅ | `phase3_language_truth.pan` |
| `null` literal | ✅ | `phase3_language_truth.pan` |
| Comments (`//`) | ✅ | All tests |
| Identifiers | ✅ | All tests |
| Semicolons (`;`) | ✅ | All tests |
| Parenthesized expressions | ✅ | `phase3_advanced.pan` |
| Block scope (`{ }`) | ✅ | `phase3_advanced.pan` (nested block shadowing) |

## Variables

| Feature | Status | Evidence |
|---------|--------|----------|
| `let` declaration | ✅ | `phase3_language_truth.pan` |
| Type inference | ✅ | `phase3_language_truth.pan` |
| Type annotations (`let x: int = 5`) | ✅ | `phase3_language_truth.pan` |
| Reassignment (`x = 5`) | ✅ | `phase3_language_truth.pan` |
| Compound assignment (`+=` `-=` `*=` `/=` `%=`) | ✅ | `phase3_compound.pan` |
| Array element assignment (`arr[0] = x`) | 💥 | "Complex assignment targets not supported" |
| Object key assignment (`obj["k"] = v`) | 💥 | Same error as array |

## Operators

| Feature | Status | Evidence |
|---------|--------|----------|
| Arithmetic: `+ - * / %` | ✅ | `phase3_language_truth.pan` |
| Exponentiation: `**` | ❓ | Check: `pow()` exists as function, `**` not as operator |
| Comparison: `== != > < >= <=` | ✅ | `phase3_language_truth.pan` |
| Logical: `&& \|\| !` | ✅ | `phase3_language_truth.pan` |
| String concat: `+` | ✅ | `phase3_language_truth.pan` |
| Indexing: `arr[0]` `obj["key"]` | ✅ | `phase3_language_truth.pan` |
| Member access: `p.name` (struct) | ✅ | `phase3_struct4.pan` |
| Range: `start..end` | ✅ | `phase3_language_truth.pan` |

## Control Flow

| Feature | Status | Evidence |
|---------|--------|----------|
| `if` / `elif` / `else` | ✅ | `phase3_language_truth.pan` |
| `while` loops | ✅ | `phase3_language_truth.pan` |
| `for i in start..end` | ✅ | `phase3_language_truth.pan` |
| For loop with array (`for i in 0..len(arr)`) | ✅ | `phase3_advanced.pan` |
| `loop` / `break` | ✅ | `phase3_language_truth.pan` |
| `continue` | ✅ | `phase3_language_truth.pan` |
| `return` | ✅ | `phase3_language_truth.pan` |
| For-in over array (`for item in arr`) | 💥 | Not supported — must use range |
| For-in over object keys | 💥 | Not supported |

## Functions

| Feature | Status | Evidence |
|---------|--------|----------|
| `fn` declaration | ✅ | `phase3_language_truth.pan` |
| Parameters | ✅ | `phase3_language_truth.pan` |
| Return value | ✅ | `phase3_language_truth.pan` |
| Recursion | ✅ | `phase3_language_truth.pan` |
| Multiple params (>2) | ❓ | `multiply(2,3,4)` showed "Undefined variable: c" — needs retest |
| Nested function calls | ✅ | `phase3_advanced.pan` |
| Nested fn definitions (fn inside fn) | ✅ | All lessons use this pattern |
| Top-level fn definitions | 💥 | Parser rejects `fn` outside `panther main` |
| Closures (fn capturing outer vars) | ⚠️ | Works but nested fn def broken in some cases |
| Function as value (pass fn reference) | ❓ | Not tested |
| Type annotations on params | ❓ | Not tested |

## Data Types

| Feature | Status | Evidence |
|---------|--------|----------|
| `int` | ✅ | `phase3_language_truth.pan` |
| `float` | ✅ | `phase3_language_truth.pan` |
| `string` | ✅ | `phase3_language_truth.pan` |
| `bool` | ✅ | `phase3_language_truth.pan` |
| `null` / none | ✅ | `phase3_language_truth.pan` |
| `any` type | ❓ | Not tested |
| Arrays `[1, 2, 3]` | ✅ | `phase3_language_truth.pan` |
| Objects `{k: v}` | ✅ | `phase3_language_truth.pan` |
| Structs | ✅ | `phase3_struct4.pan` |
| Enums | 💥 | Parser works but runtime fails (Undefined variable: Color) |
| Traits | 💥 | Parser code exists but trait method syntax is broken |

## Top-Level Blocks

| Feature | Status | Evidence |
|---------|--------|----------|
| `panther main { }` | ✅ | All tests |
| `web { }` | ✅ | `recipes/19-web.pan` |
| `api { }` | ❓ | Parser accepts but no evidence of runtime support |
| `ai { }` | ❓ | Parser accepts but no evidence of runtime support |
| `test { }` | ❓ | Parser accepts but no evidence of runtime support |

## Print/Output

| Feature | Status | Evidence |
|---------|--------|----------|
| `print "text"` | ✅ | All tests |
| `print string(expr)` | ✅ | `phase3_language_truth.pan` |
| `print expr` (bare) | ✅ | `phase3_advanced.pan` — `print "a"` works |
| Print with math expression | 💥 | `print 10 + 5 * 2` fails — must wrap in `string()` |

## Modules/Imports

| Feature | Status | Evidence |
|---------|--------|----------|
| `import` statement | ❓ | Parser code exists but untested |

## Cross-Type Semantics

| Feature | Status | Evidence |
|---------|--------|----------|
| Explicit conversion (`int()`, `float()`, `string()`) | ✅ | `docs/cookbook/recipes/02-types.pan` |
| Cross-type comparison blocked (PT002) | ✅ | Book Chapter 15, verified |
| Division by zero error (PR001) | ✅ | Book Chapter 14 |
| Implicit conversion blocked (PT001) | ✅ | Book Chapter 15 |

## Summary

| Classification | Count | Items |
|----------------|-------|-------|
| ✅ IMPLEMENTED_PROVEN | ~30 | Core language basics |
| ⚠️ IMPLEMENTED_PARTIAL | ~3 | Closures, nested blocks |
| ❌ IMPLEMENTED_UNPROVEN | ~10 | api/ai/test blocks, import |
| 📝 DOCUMENTED_ONLY | 0 | — |
| 🔮 PLANNED | 0 | — |
| 💥 BROKEN | 4 | Enum, Trait, Array element assignment, Object key assignment |
| ❓ CONTRADICTORY | 1 | `**` operator claimed in docs but not present |
