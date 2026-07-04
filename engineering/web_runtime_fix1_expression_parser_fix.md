# Web Runtime Fix 1 — Expression Parser Regression Fix

Fixes object/array literal parsing after parser brace tracking changes.

## Scope
- Restores known-good `compiler/parser/expression_parser.py`.
- Restores known-good `compiler/parser/statement_parser.py` with balanced `{}` tracking.
- Adds regression tests for object literals, array literals, indexing, and object-literal route returns.

## Validation
- Targeted tests must pass.
- Existing web parser brace tests must pass.
- Full regression should pass before release.
