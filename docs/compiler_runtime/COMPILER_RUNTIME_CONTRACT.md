# PantherLang Compiler Runtime Contract

## Purpose

R3 Batch 2 starts the real compiler/runtime line.

The goal is to move from VS Code command wiring and build scaffolds into a real language execution pipeline.

## Pipeline

1. Lex
2. Parse
3. AST
4. Semantic Check
5. IR
6. Runtime Execute
7. Artifact Emit

## Supported Source Files

- `.panther`
- `.pan`

## Supported Entrypoints

- `panther main`
- `panther web`
- `panther api`
- `panther ai`
- `panther test`

## Current Part

Part 1 creates the contract only. Real lexer/parser work starts in Part 2.
