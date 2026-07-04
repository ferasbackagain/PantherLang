# Chapter 3: Expressions and Operators

## Arithmetic

```panther
let a = 42;
let b = 7;
print a + b;    // 49
print a - b;    // 35
print a * b;    // 294
print a / b;    // 6 (integer division)
print a % b;    // 0
print a ** 2;   // 1764
```

## Comparison

```panther
print 10 > 3;      // true
print 10 == 3;     // false
print 10 < 3;      // false
print 10 >= 3;     // true
print 10 <= 3;     // false
print 10 != 3;     // true
```

## Logical

```panther
print true && false;    // false
print true || false;    // true
print !true;            // false
```

## String Concatenation

```panther
print "Hello " + "World";    // "Hello World"
print "Value: " + string(42); // "Value: 42"
```

## Operator Precedence (highest to lowest)

1. `()` grouping, `[]` index, `.` member
2. Unary `+`, `-`, `!`
3. `**` (right-associative)
4. `*`, `/`, `%`
5. `+`, `-`
6. `>`, `>=`, `<`, `<=`
7. `==`, `!=`
8. `&&`
9. `||`
