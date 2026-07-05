# Capstone: URL Shortener

## Level
Intermediate

## Track
Data

## Prerequisites
- Academy Lessons 1-9
- Book Chapters 1-7

## Objective
Build a URL shortener that stores mappings in SQLite, generates short codes using SHA-256 hashing, and displays the full mapping table.

## Requirements
1. Use `db_open(":memory:")` for an in-memory SQLite database
2. Use `db_execute` to CREATE TABLE and INSERT records
3. Use `db_query` for SELECT operations
4. Generate short codes using `sha256` and `substring`
5. Store and retrieve URL mappings
6. Print the full mapping table at the end
7. Handle duplicate URLs by returning existing short codes

## Rubric
| Criteria | Points |
|----------|--------|
| Functionality | 40 |
| Database design | 20 |
| Short code generation | 20 |
| Documentation | 20 |

## Solution
Run: `python -m cli.panther_cli run docs/capstones/solutions/url-shortener.pan`

## Verification
Expected output (short codes depend on SHA-256 of URLs):
```
=== Panther URL Shortener ===
[DATABASE] In-memory SQLite initialized
[TABLE] Created table: url_mappings
[INSERT] Short code 'a1b2c3d4' -> https://example.com/docs
[INSERT] Short code 'e5f6g7h8' -> https://pantherlang.org
[INSERT] Short code 'i9j0k1l2' -> https://github.com
[DUPLICATE] URL already exists: a1b2c3d4
All Mappings:
  <8-char-hex> -> https://example.com/docs
  <8-char-hex> -> https://pantherlang.org
  <8-char-hex> -> https://github.com
=== URL Shortener Complete ===
```
