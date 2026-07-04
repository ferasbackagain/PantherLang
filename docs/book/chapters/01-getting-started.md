# Chapter 1: Getting Started

## What is PantherLang?

PantherLang is a modern, secure, AI-native programming language. It features a tree-walking interpreter, 43 built-in standard library functions, a type checker, semantic analyzer, and cross-platform tooling. Programs are written in `.panther` or `.pan` files.

## Installation

```bash
pip install pantherlang
# or from source (Developer Edition):
pip install -e ".[dev]"
```

## Verify

```bash
panther doctor
```

## Your First Program

```panther
panther main {
    let name = "PantherLang";
    let year = 2026;
    print "Hello from " + name;
    print "Year: " + string(year);
}
```

Save as `hello.pan` and run:

```bash
panther run hello.pan
```

## The `panther main { }` Block

Every PantherLang program must have a `panther main { }` block as its entry point. All executable code goes inside this block. Functions can be declared inside it, and variables are scoped to it.

## CLI Commands

- `panther run <file>` — Execute a program
- `panther check <file>` — Validate syntax without running
- `panther new <type> <name>` — Scaffold a project (console, web, api, ai)
- `panther doctor` — Check system components

## Running the Examples

```bash
panther run examples/console_hello/main.pan
panther run examples/calculator/calc.pan
```
