# docs/specification/README.md

# PantherLang Language Specification

## Overview

The PantherLang Language Specification is the official documentation describing the PantherLang programming language. This directory contains formal specifications for each aspect of the language, grounded in the actual implementation.

## Specification Documents

| # | Document | Description |
|---|----------|-------------|
| 1 | [01_LEXICAL_SPECIFICATION.md](01_LEXICAL_SPECIFICATION.md) | Character set, tokens, keywords, literals |
| 2 | [02_GRAMMAR_EBNF.md](02_GRAMMAR_EBNF.md) | Complete EBNF grammar with precedence |
| 3 | [03_KEYWORDS.md](03_KEYWORDS.md) | All reserved keywords with descriptions |
| 4 | [04_OPERATORS.md](04_OPERATORS.md) | Operators, precedence, type compatibility |
| 5 | [05_TYPE_SYSTEM_SPECIFICATION.md](05_TYPE_SYSTEM_SPECIFICATION.md) | Types, annotations, inference, compatibility |
| 6 | [06_RUNTIME_SPECIFICATION.md](06_RUNTIME_SPECIFICATION.md) | Execution model, environment, control flow |
| 7 | [07_MODULE_SPECIFICATION.md](07_MODULE_SPECIFICATION.md) | Import syntax, resolution, standard library |
| 8 | [08_ERROR_SPECIFICATION.md](08_ERROR_SPECIFICATION.md) | Error codes E001-E008, T001, S001-S005 |

## Version

**PantherLang 1.0.0** — matches the current implementation.

## Verification

All specifications are grounded in the actual implementation. To verify:

```bash
python -m pytest
# Expected: 1006 passed, 0 failed
```

## Latest Updates

The specifications are continuously updated to match the current implementation. Each document is validated against the existing compiler, parser, runtime, and test suite.

## How to Use

- **For Developers**: Read specifications to understand language features
- **For Compiler Writers**: Use EBNF grammar for parser implementation
- **For Tool Writers**: Refer to error codes for diagnostics
- **For AI Systems**: Use for generating correct PantherLang code
- **For Educators**: Use for teaching language concepts

## Contributing

If you find discrepancies between the specification and implementation, please report them via GitHub issues. All specifications should be 100% compliant with the current implementation.
