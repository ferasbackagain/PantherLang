# Chapter 15: Comparison Semantics

## Overview

PantherLang enforces strict comparison semantics. Unlike many languages that perform implicit type coercion during comparisons, PantherLang requires **explicit conversion** for all cross-type comparisons. This chapter covers the complete comparison model, rationale, and patterns.

## The Core Rule

> **PantherLang does not perform implicit comparison conversion.**
>
> All comparison operators (`==`, `!=`, `>`, `<`, `>=`, `<=`) must operate on compatible types.

This policy keeps arithmetic and comparison behavior consistent with the language rule: **explicit conversion only**.

## Same-Type Comparisons (Always Allowed)

### Numbers
```panther
let a = 100;
let b = 50;
print a == b;   // false
print a != b;   // true
print a > b;    // true
print a < b;    // false
print a >= a;   // true
print b <= a;   // true
```

### Strings
```panther
let s1 = "Panther";
let s2 = "Lang";
print s1 == s2;  // false
print s1 != s2;  // true
print s1 < s2;   // true (lexicographic)
print s1 > s2;   // false
```

### Booleans
```panther
print true == true;   // true
print true == false;  // false
print false != true;  // true
```

### Null
```panther
print null == null;   // true
print null != null;   // false
```

## Different-Type Comparisons (Blocked — PT002)

The following produce **PT002: Type mismatch in comparison**:

```panther
// Number vs String
100 == "100"      // PT002
100 != "100"      // PT002
100 > "50"        // PT002

// Boolean vs Number
true == 1         // PT002
false == 0        // PT002

// String vs Boolean
"true" == true    // PT002
"false" == false  // PT002
```

## Explicit Conversion Patterns

### Number ↔ String
```panther
// String to number
to_int("100") == 100        // true
to_number("3.14") == 3.14   // true

// Number to string
to_string(100) == "100"     // true
string(100) == "100"        // true (alias)
```

### Boolean ↔ Number
```panther
to_bool(1) == true          // true
to_bool(0) == false         // true
to_int(true) == 1           // true
to_int(false) == 0          // true
```

### Boolean ↔ String
```panther
to_string(true) == "true"   // true
to_bool("true") == true     // true
to_bool("false") == false   // true
```

## Null Comparison Semantics

Null can be compared with **any type** using `==` and `!=`:

```panther
print null == "hello";   // false
print "hello" == null;   // false
print null != "hello";   // true
print null == 42;        // false
print 42 == null;        // false
print null == true;      // false
print null != 42;        // true
print null == null;      // true
print null != null;      // false
```

**Ordered comparisons with null are blocked (PT002):**
```panther
print null > 5;          // PT002
print null < "hello";    // PT002
```

## Comparison with Variables

```panther
let response = null;
if response == null {
    print "No response received";
}

let age = 25;
let input = "25";
if age == to_int(input) {
    print "Age matches";
}
```

## Rationale

1. **Predictability**: No hidden type coercion means no surprise results
2. **Safety**: Catches type mismatches at compile/check time
3. **Consistency**: Arithmetic already requires explicit conversion; comparison follows the same rule
4. **Performance**: No runtime type juggling overhead
5. **Clarity**: Code explicitly shows intent

## Common Patterns

### Input Validation
```panther
let user_age = input("Enter age: ");
if to_int(user_age) >= 18 {
    print "Adult";
} else {
    print "Minor";
}
```

### Configuration Comparison
```panther
let config = json_decode(read_file("config.json"));
let expected_version = "1.0.0";
if config["version"] == expected_version {
    print "Version matches";
}
```

### Null Checks
```panther
let result = db_query(conn, "SELECT * FROM users WHERE id = ?", [1]);
if result == null || len(result) == 0 {
    print "User not found";
}
```

## Error Codes Reference

| Code | Trigger |
|------|---------|
| PT002 | Comparison between incompatible types |
| T001 | Type mismatch in expressions (related) |

## Summary

| Comparison | Same Type | Different Type | Null |
|------------|-----------|----------------|------|
| `==`, `!=` | ✅ Allowed | ❌ PT002 | ✅ Allowed |
| `>`, `<`, `>=`, `<=` | ✅ Allowed | ❌ PT002 | ❌ PT002 |

**Remember**: When in doubt, convert explicitly. `to_string()`, `to_int()`, `to_number()`, `to_bool()` are your tools for safe, clear comparisons.