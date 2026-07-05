# PantherLang v1.1.6 Academy-Book Alignment Matrix

**Date:** 2026-07-04  
**Purpose:** Map Academy lessons to Book chapters for coherence

---

## Lesson ↔ Chapter Mapping

| Academy Lesson | Book Chapter | Alignment Status | Issues |
|----------------|--------------|------------------|--------|
| **01: Expressions & Operators** | **03: Expressions and Operators** | ✅ ALIGNED | Different order (Academy 1st, Book 3rd) |
| **02: Variables & Types** | **02: Variables and Types** | ✅ ALIGNED | Same title, good |
| **03: Control Flow** | **04: Control Flow** | ❌ MISALIGNED | Lesson 03 content is variables, not control flow |
| **04: Functions** | **05: Functions** | ❌ MISALIGNED | Lesson 04 content is arithmetic, not functions |
| **05: Conversions & IO** | **02 (partial), 07 (partial)** | ⚠️ SPLIT | Conversions in Ch 2 & 7, IO not in book |
| **06: Arrays & Collections** | **06: Data Structures** | ❌ MISALIGNED | Lesson 06 is comparisons, Ch 06 is arrays/objects/structs |
| **07: Modules & Packages** | **14: Language Reference (partial)** | ❌ MISSING | No dedicated chapter, Lesson 07 missing |
| **08: Web Development** | **09: Web Platform** | ❌ MISSING | Lesson 08 missing |
| **09: AI & Machine Learning** | **11: AI Platform** | ❌ MISSING | Lesson 09 missing |
| **10: Advanced Security** | **08: Security** | ❌ MISSING | Lesson 10 missing |

---

## Content Overlap Analysis

### Well-Aligned (Academy → Book)
| Topic | Academy Coverage | Book Coverage | Gap |
|-------|-----------------|---------------|-----|
| Expressions | Lesson 01 (basic) | Ch 03 (comprehensive) | Book deeper |
| Variables | Lesson 02 (minimal) | Ch 02 (comprehensive) | Book deeper |
| Control Flow | Lesson 03 (NONE) | Ch 04 (comprehensive) | Academy missing |
| Functions | Lesson 04 (NONE) | Ch 05 (comprehensive) | Academy missing |
| Data Structures | Lesson 06 (NONE) | Ch 06 (comprehensive) | Academy missing |
| Stdlib | Lesson 05 (partial) | Ch 07 (comprehensive) | Book deeper |
| Security | Lesson 10 (missing) | Ch 08 (comprehensive) | Academy missing |
| Web | Lesson 08 (missing) | Ch 09 (comprehensive) | Academy missing |
| Database | N/A | Ch 10 (comprehensive) | Academy missing |
| AI | Lesson 09 (missing) | Ch 11 (comprehensive) | Academy missing |

### Book-Only Topics (No Academy Lesson)
- Chapter 10: Database Platform
- Chapter 12: CLI and Tooling
- Chapter 13: Cross-Platform
- Chapter 14: Language Reference
- Chapter 15: Comparison Semantics (minimal)

### Academy-Only Topics (No Book Chapter)
- Lesson 01: First program / CLI basics (Book Ch 01 covers this)
- Lesson 05: IO operations (input, readline, println) — not in book

---

## Terminology Consistency Check

| Concept | Academy Term | Book Term | Match |
|---------|-------------|-----------|-------|
| Entry point | `panther main { }` | `panther main { }` | ✅ |
| Variables | `let` | `let` | ✅ |
| Type annotations | `let x: int = 5` | `let x: int = 5` | ✅ |
| Type conversion | `to_string()`, `to_int()` | `string()`, `int()` | ❌ INCONSISTENT |
| Arrays | `[1,2,3]` | `[1,2,3]` | ✅ |
| Objects | `{key: val}` | `{key: val}` | ✅ |
| Structs | Not in academy | `struct Name { fields }` | N/A |
| Functions | `fn name() { }` | `fn name() { }` | ✅ |
| If/else | N/A | `if/elif/else` | N/A |
| Loops | N/A | `while`, `for`, `loop` | N/A |
| Error codes | PT001, PR001, PT002 | T001, PT001, PT002 | ⚠️ Partial |

---

## Syntax Consistency Check

| Syntax Element | Academy Examples | Book Examples | Match |
|----------------|-----------------|---------------|-------|
| Comments | `//` | `//` | ✅ |
| Strings | `"hello"` | `"hello"` | ✅ |
| Numbers | `42`, `3.14` | `42`, `3.14` | ✅ |
| Booleans | `true`, `false` | `true`, `false` | ✅ |
| Null | `null` | `null` | ✅ |
| Array indexing | `arr[0]` | `arr[0]` | ✅ |
| Object indexing | `obj["key"]` | `obj["key"]` | ✅ |
| Function call | `fn_name(args)` | `fn_name(args)` | ✅ |
| Type conversion | `to_string(x)` | `string(x)` | ❌ |

**Critical Finding:** Academy uses `to_string()`, `to_int()`, `to_float()`, `to_bool()`, `type_of()` but Book uses `string()`, `int()`, `float()`. Both exist in implementation (`compiler/stdlib/functions.py`) but are different functions with different behaviors.

---

## Learning Progression Comparison

### Academy Progression (Claimed)
1. Expressions & Operators
2. Variables & Types
3. Control Flow
4. Functions
5. Conversions & IO
6. Arrays & Collections
7. Modules & Packages
8. Web Development
9. AI & ML
10. Advanced Security

### Book Progression (Actual)
1. Getting Started
2. Variables and Types
3. Expressions and Operators
4. Control Flow
5. Functions
6. Data Structures
7. Standard Library
8. Security
9. Web Platform
10. Database Platform
11. AI Platform
12. CLI and Tooling
13. Cross-Platform
14. Language Reference
15. Comparison Semantics

### Optimal Unified Progression (Recommended)
1. **Getting Started** (Book Ch 01) → Academy Lesson 01
2. **Variables & Types** (Book Ch 02) → Academy Lesson 02
3. **Expressions & Operators** (Book Ch 03) → Academy Lesson 01 (merge)
4. **Control Flow** (Book Ch 04) → Academy Lesson 03
5. **Functions** (Book Ch 05) → Academy Lesson 04
6. **Data Structures** (Book Ch 06) → Academy Lesson 06
7. **Type Conversions & IO** (Book Ch 02+07) → Academy Lesson 05
8. **Standard Library** (Book Ch 07) → Academy Lesson (new)
9. **Structs, Enums, Traits** (Book Ch 14) → Academy Lesson (new)
10. **Modules & Packages** (Book Ch 14) → Academy Lesson 07
11. **Security** (Book Ch 08) → Academy Lesson 10
12. **Web Platform** (Book Ch 09) → Academy Lesson 08
13. **Database Platform** (Book Ch 10) → Academy Lesson (new)
14. **AI Platform** (Book Ch 11) → Academy Lesson 09
15. **CLI & Tooling** (Book Ch 12) → Academy Lesson (new)
16. **Advanced Topics** (Book Ch 13, 14) → Academy Lesson (new)

---

## Cross-Reference Requirements

Every Book Chapter should reference:
- [ ] Corresponding Academy Lesson(s)
- [ ] Prerequisite lessons
- [ ] Follow-up lessons

Every Academy Lesson should reference:
- [ ] Corresponding Book Chapter(s)
- [ ] Specification section (PDL-XXX)
- [ ] Runnable example file
- [ ] Exercise/lab/quiz

**Current State:** 0/30 cross-references exist

---

## Verdict

**Academy and Book are NOT aligned.** They were developed independently with:
- Different lesson/chapter ordering
- Different terminology for type conversion
- Academy lessons 03, 04, 06 teaching wrong topics
- No cross-references
- Book has 5 chapters with no Academy counterpart
- Academy has 4 missing lessons that Book covers

**Recommendation:** Unify into single curriculum with 16-18 lessons matching Book chapters, using Book as authoritative content source and Academy as interactive practice layer.