# Chapter 2: Variables and Types

## Variable Declaration

Use `let` to declare a variable:

```panther
let name = "PantherLang";    // string (inferred)
let year = 2026;             // int (inferred)
let pi = 3.14;               // float (inferred)
let is_ready = true;         // bool (inferred)
let data = null;             // null
```

## Type Annotations

Optional type annotations are verified by the type checker:

```panther
let count: int = 42;
let label: string = "total";
let ratio: float = 0.5;
let flag: bool = false;
let result: any = null;
```

Supported primitive types: `int`, `float`, `string`, `bool`, `null`, `any`.

## Reassignment

```panther
let x = 10;
x = 20;
```

## Compound Assignment

```panther
x += 5;    // x = x + 5
x -= 3;    // x = x - 3
x *= 2;    // x = x * 2
x /= 4;    // x = x / 4
x %= 3;    // x = x % 3
```

## Type Conversion

```panther
string(42)      // "42"
int("42")       // 42
float("3.14")   // 3.14
```
