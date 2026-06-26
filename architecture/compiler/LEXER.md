# PantherLang Lexer — Phase 1.2

## Purpose
The lexer converts Panther source code into a stream of tokens.

## Input
A `.panther` source file.

## Output
A list of tokens with:
- type
- value
- line
- column

## Supported Tokens
- Keywords
- Identifiers
- Strings
- Numbers
- Symbols
- Comments
- EOF

## Design Rules
1. The lexer must be deterministic.
2. Every token must preserve source location.
3. Unknown characters must produce clear diagnostics.
4. The lexer must be simple enough for AI systems to understand and generate.
