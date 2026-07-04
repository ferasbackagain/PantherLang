# Phase 2 Batch 2.1 Part 1 — Expression AST Foundation

This batch formalizes the PantherLang expression AST contract.

Implemented foundation:

- `ExpressionOperator`
- `ExpressionPrecedence`
- operator precedence table
- unary / binary / assignment operator classification
- right-associativity classification
- `GroupingExpression`
- stable children contracts for expression nodes
- regression tests for the expression AST layer

This part intentionally does not replace the parser yet. Parser integration belongs to Batch 2.1 Part 2.
