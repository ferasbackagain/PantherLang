# PantherLang Cookbook

## Overview

The PantherLang Cookbook provides **79 verified examples** across 19 recipe categories. Each recipe is a runnable `.pan` file that demonstrates real, working PantherLang syntax.

All recipes are verified to run with:

```bash
python -m cli.panther_cli run docs/cookbook/recipes/cookbook_all.pan
```

## Recipes (20 verified)

| # | Category | File | Functions Demonstrated |
|---|----------|------|----------------------|
| 01 | **Basics** | `01-basics.pan` | print, string concat, variables |
| 02 | **Types** | `02-types.pan` | int(), float(), string(), null, bool |
| 03 | **Arithmetic** | `03-arithmetic.pan` | + - * / %, pow, sqrt, abs, max, min, floor, ceil, round |
| 04 | **Control Flow** | `04-control-flow.pan` | if/elif/else, for range, while, loop, break, continue |
| 05 | **Functions** | `05-functions.pan` | fn, params, return, recursion |
| 06 | **Arrays** | `06-arrays.pan` | array creation, indexing, push, pop, sort, reverse |
| 07 | **Objects** | `07-objects.pan` | object literals, key access, JSON round-trip |
| 08 | **Strings** | `08-strings.pan` | len, upper, lower, trim, contains, starts/ends_with, replace, split, join, substring |
| 09 | **Filesystem** | `09-filesystem.pan` | mkdir, write_file, read_file, file_exists, list_dir, remove_file |
| 10 | **JSON** | `10-json.pan` | json_encode, json_decode |
| 11 | **Security** | `11-security.pan` | sha256, hmac_sha256, secure_token, secure_compare, sanitize_path, sanitize_html |
| 12 | **Math** | `12-math.pan` | abs, max, min, pow, sqrt, floor, ceil, round, random, randint, time, sleep |
| 13 | **Regex** | `13-regex.pan` | regex_match, regex_replace, regex_split |
| 14 | **HTTP** | `14-http.pan` | http_get, http_post |
| 15 | **Collections** | `15-collections.pan` | array_push, array_pop, array_sort, array_reverse |
| 16 | **SQLite** | `16-sqlite.pan` | db_open, db_execute, db_query, db_close |
| 17 | **Comparisons** | `17-comparisons.pan` | == != > < >= <= for int/str/bool/float |
| 18 | **CLI** | `18-cli.pan` | CLI reference (panther run/build/check/new/doctor) |
| 19 | **Web** | `19-web.pan` | route GET/POST, params, body |
| — | **All Recipes** | `cookbook_all.pan` | Master runner: all 19 recipes in one file |

## Running Recipes

```bash
# Single recipe
python -m cli.panther_cli run docs/cookbook/recipes/03-arithmetic.pan

# All recipes
python -m cli.panther_cli run docs/cookbook/recipes/cookbook_all.pan
```

## Cookbook Philosophy

- **Verified Examples**: All recipes pass `panther run`
- **Practical Focus**: Real-world scenarios and common use cases
- **Security-First**: All examples follow PantherLang security best practices
- **Cross-Platform**: Examples work on Linux, macOS, Windows

## Key Syntax Notes

- `for i in start..end` — range is **inclusive on both ends**
- `string()` — use for type conversion (not `to_string()`)
- `join(sep, items)` — separator is first argument
- `regex_match(pattern, text)` — pattern is first argument
- `sanitize_path(base, path)` — takes two arguments
- `array_sort` / `array_reverse` — return new arrays (don't modify in place)
- `array_push` — modifies in place and returns new length

## Resources

- **Panther Academy**: `academy/` with 18 structured lessons
- **Panther Book**: `docs/book/` with comprehensive reference
- **Examples**: `examples/` with 11 runnable example projects
