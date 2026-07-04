# Chapter 14: Language Reference

## Lexical Structure

- **Comments**: `//` single-line only
- **Identifiers**: letters, digits, underscores; must start with letter or underscore
- **String escapes**: `\n`, `\t`, `\"`, `\\`
- **Numbers**: integer (`42`) and float (`3.14`) decimal literals

## Keywords (16)

```
panther main web api ai test
print return route get post
true false null assert prompt
```

## Operators

| Category | Operators |
|----------|-----------|
| Arithmetic | `+`, `-`, `*`, `/`, `%`, `**` |
| Compound assignment | `+=`, `-=`, `*=`, `/=`, `%=` |
| Comparison | `==`, `!=`, `>`, `>=`, `<`, `<=` |
| Logical | `&&`, `\|\|`, `!` |
| Index | `[`, `]` |
| Member | `.`, `->` |
| Separators | `{`, `}`, `(`, `)`, `,`, `:`, `;` |

## Top-Level Blocks

```
panther main { ... }    // Entry point — executable
web { ... }             // Web block
api { ... }             // API block
ai { ... }              // AI block
test "name" { ... }     // Test block
```

## Statements

```
let x = expr;           // variable declaration
let x: type = expr;     // typed declaration
x = expr;               // assignment
x += expr;              // compound assignment
print expr;             // output
return expr;            // return with value
return;                 // return without value
if cond { ... } elif cond { ... } else { ... }
while cond { ... }
for id in start..end { ... }
loop { ... }
break;
continue;
fn id(params) { ... }
fn id(params): type { ... }
route GET "/path" { ... }
route POST "/path" { ... }
struct Name { fields }
enum Name { VARIANTS }
trait Name { fn sig(params); }
import module;
import module as alias;
{ ... }                 // nested block
```

## Standard Library Categories

- **String** (11): len, substring, contains, starts_with, ends_with, upper, lower, trim, replace, split, join
- **Math** (10): abs, max, min, pow, sqrt, floor, ceil, round, random, randint
- **JSON** (2): json_encode, json_decode
- **Time** (2): time, sleep
- **Type Conversion** (3): int, float, string
- **Crypto** (4): sha256, hmac_sha256, secure_token, secure_compare
- **Security** (2): sanitize_path, sanitize_html
- **Filesystem** (6): read_file, write_file, file_exists, mkdir, list_dir, remove_file
- **HTTP** (2): http_get, http_post
- **Regex** (3): regex_match, regex_replace, regex_split
- **Collections** (4): array_push, array_pop, array_sort, array_reverse
- **SQLite** (4): db_open, db_close, db_execute, db_query

## Error Codes

| Code | Description |
|------|-------------|
| E001 | Break outside loop |
| E002 | Continue outside loop |
| E003 | Duplicate function declaration |
| E005 | Duplicate variable declaration |
| E006 | Duplicate import |
| E007 | Undefined variable referenced |
| E008 | Undefined function/symbol |
| T001 | Type mismatch / incompatibility |
| S001 | Hardcoded secret in string literal |
| S002 | Dangerous function name |
| S003 | Dangerous function call |
| S004 | Dangerous shell pattern |
| S005 | Secret pattern in string value |
