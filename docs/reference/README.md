# docs/reference/README.md

# PantherLang Developer Reference

## Overview

The Developer Reference provides practical guidance for developers working with PantherLang. It covers language usage, best practices, platform integration, and troubleshooting guides.

## Documentation Structure

### Language Fundamentals
- [specification/01_LEXICAL_SPECIFICATION.md](specification/01_LEXICAL_SPECIFICATION.md) - Language specification
- [specification/02_GRAMMAR_EBNF.md](specification/02_GRAMMAR_EBNF.md) - Grammar and parsing rules
- [specification/03_KEYWORDS.md](specification/03_KEYWORDS.md) - Complete keyword list
- [specification/04_OPERATORS.md](specification/04_OPERATORS.md) - Operator definitions
- [specification/05_TYPE_SYSTEM_SPECIFICATION.md](specification/05_TYPE_SYSTEM_SPECIFICATION.md) - Type system rules

### Development Guides
- [specification/06_RUNTIME_SPECIFICATION.md](specification/06_RUNTIME_SPECIFICATION.md) - Execution model
- [specification/07_MODULE_SPECIFICATION.md](specification/07_MODULE_SPECIFICATION.md) - Import and module system
- [specification/08_ERROR_SPECIFICATION.md](specification/08_ERROR_SPECIFICATION.md) - Error codes and diagnostics

### Practical References
- [language_reference.md](language_reference.md) - Complete language syntax and semantics

## Quick Start

### Installation
```bash
pip install pantherlang
```

### Project Setup
```bash
panther new console myproject
cd myproject
panther run src/main.panther
```

### Basic Usage
```panther
// Variables and types
let name: string = "PantherLang";
let count: int = 42;
let active: bool = true;
let data: any = "mixed";

// Functions
fn greet(msg) {
    return "Hello: " + msg;
}

// Control flow
if name != "PantherLang" {
    print "Custom greeting";
} else {
    print "Default greeting";
}

// Collections
let arr = [1, 2, 3];
let obj = {key: "value"};

// Output
print "Hello, World!";
```