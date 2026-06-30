# R3 Batch 2 Part 3.2.6 — Parser Tests

This segment consolidates parser verification for the current Recursive Descent Parser Core.

Delivered coverage:

- Full current-surface program parsing across `panther main`, `web`, `api`, `ai`, and `test` blocks
- Route body AST preservation
- Program serialization contract
- Source location stability
- Missing block-close diagnostics
- Missing semicolon diagnostics
- Recovery after invalid top-level tokens
- Empty program contract
- TokenStream checkpoint/rollback regression
- Expression statement placeholder contract pending Part 3.3
- Literal materialization checks
- Test block name/body preservation

The segment also marks `compiler.ast.program.TestBlockNode.__test__ = False` so pytest does not emit collection warnings when the AST class is imported into test modules.
