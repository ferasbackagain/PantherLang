# Engineering Report — Phase 2 Batch 2.1 Part 1

## Scope
Expression AST foundation for PantherLang Language Core.

## Files touched
- `compiler/ast/expressions.py`
- `compiler/ast/__init__.py`
- `tests/phase2_batch2_1/test_expression_ast_foundation.py`
- `docs/phase2/expression_ast_foundation.md`
- `manifests/phase2_batch2_1_part1_manifest.json`

## Verification
The bootstrap runs targeted tests first, then the full regression with `python3 -m pytest -q`.

## Completion rule
This part is complete only when regression returns the existing baseline successfully.
