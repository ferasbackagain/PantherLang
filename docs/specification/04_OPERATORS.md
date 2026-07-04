# PantherLang Operators

## Arithmetic

| Operator | Description | Example | Result |
|----------|-------------|---------|--------|
| `+` | Addition | `3 + 4` | `7` |
| `-` | Subtraction | `10 - 3` | `7` |
| `*` | Multiplication | `3 * 4` | `12` |
| `/` | Integer Division | `10 / 3` | `3` |
| `%` | Modulo | `10 % 3` | `1` |
| `**` | Power | `2 ** 3` | `8` |
| `-` (unary) | Negation | `-5` | `-5` |
| `+` (unary) | Identity | `+5` | `5` |

## Comparison

| Operator | Description | Example | Result |
|----------|-------------|---------|--------|
| `==` | Equal | `3 == 3` | `true` |
| `!=` | Not equal | `3 != 4` | `true` |
| `>` | Greater than | `5 > 3` | `true` |
| `>=` | Greater or equal | `5 >= 5` | `true` |
| `<` | Less than | `3 < 5` | `true` |
| `<=` | Less or equal | `3 <= 3` | `true` |

## Logical

| Operator | Description | Example | Result |
|----------|-------------|---------|--------|
| `&&` | Logical AND | `true && false` | `false` |
| `\|\|` | Logical OR | `true \|\| false` | `true` |
| `!` | Logical NOT | `!true` | `false` |

## Assignment

| Operator | Description | Example | Equivalent |
|----------|-------------|---------|------------|
| `=` | Assign | `x = 5` | `x = 5` |
| `+=` | Add and assign | `x += 3` | `x = x + 3` |
| `-=` | Subtract and assign | `x -= 3` | `x = x - 3` |
| `*=` | Multiply and assign | `x *= 3` | `x = x * 3` |
| `/=` | Divide and assign | `x /= 3` | `x = x / 3` |
| `%=` | Modulo and assign | `x %= 3` | `x = x % 3` |

## Access

| Operator | Description | Example |
|----------|-------------|---------|
| `.` | Member (struct field) | `point.x` |
| `()` | Function call | `add(3, 4)` |
| `[]` | Index (array/object) | `arr[0]`, `obj["key"]` |

## Precedence (lowest to highest)

| Level | Category | Operators | Assoc |
|-------|----------|-----------|-------|
| 10 | Assignment | `= += -= *= /= %=` | Right |
| 20 | Logical OR | `\|\|` | Left |
| 30 | Logical AND | `&&` | Left |
| 40 | Equality | `== !=` | Left |
| 50 | Comparison | `> >= < <=` | Left |
| 60 | Addition | `+ -` | Left |
| 70 | Multiplication | `* / %` | Left |
| 80 | Power | `**` | Right |
| 90 | Unary | `! - +` | Right |
| 100 | Postfix | `. () []` | Left |

## Type Compatibility

| Operation | Valid Types | Result |
|-----------|-------------|--------|
| `+` | int + int → int, float + float → float, string + string → string |
| `-`, `*`, `/`, `%` | int/int, float/float | numeric |
| `**` | int ** int → int, float ** float → float |
| `==`, `!=` | any comparable type | bool |
| `>`, `>=`, `<`, `<=` | numeric types | bool |
| `&&`, `\|\|` | bool only | bool |
| `!` | bool only | bool |
