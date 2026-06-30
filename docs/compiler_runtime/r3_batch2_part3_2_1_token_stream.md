# R3 Batch 2 Part 3.2.1 — Token Stream

This segment introduces the parser-facing token navigation foundation for the PantherLang recursive-descent parser.

## Delivered Files

- `compiler/parser/token_stream.py`
- `compiler/parser/cursor.py`
- `compiler/parser/parse_error.py`
- `compiler/parser/parser_base.py`
- `compiler/parser/__init__.py`
- `tests/R3_compiler_runtime/test_r3_batch2_part3_2_1_token_stream.py`

## Capabilities

- EOF-guarded token stream over lexer output.
- Safe lookahead with clamped EOF behavior.
- `advance`, `match`, `consume`, `consume_any` parser primitives.
- Checkpoint and rollback for recursive-descent speculation.
- Structured `ParseError` diagnostics with source location and expected tokens.
- `ParserBase` delegates navigation and provides synchronization for upcoming parser segments.

## Next Segment

R3 Batch 2 Part 3.2.2 — Parser Infrastructure.
