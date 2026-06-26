# PantherLang IR Engine — Phase 1.5

## Purpose
IR means Intermediate Representation.

The IR is the stable internal format between:
- Parser
- Semantic Engine
- Type Checker
- Runtime
- Future Code Generator

## Pipeline
Source → Lexer → Tokens → Parser → AST → Semantic Engine → IR → Runtime/Codegen

## Phase 1.5 Scope
This phase introduces the first official Panther IR model:
- IRProgram
- IRModel
- IRField
- IRBuilder

## Design Rules
1. IR must be simple.
2. IR must be serializable.
3. IR must be independent from Python implementation details.
4. IR must support future targets: native, WASM, web, cloud, AI runtime.
