# PantherLang Official Vision Review

Founder: Feras Khatib
Branch: R3 — Compiler Runtime
Policy: No Feature Without Proof

## Strategic Decision

Panther Calculator becomes the first official reference application for PantherLang.
This prevents the language from growing as disconnected syntax fragments. Every new
feature must be used immediately in a real program.

## Current Engineering Position

The compiler/runtime/parser core has already moved past the earliest foundation
work. The active blocker is Debug Adapter compatibility: old public test contracts
expect names such as `Launcher`, `VariableStore`, and `VariablesCore`, while newer
internal services evolved under different names.

The correct fix is not to delete the modern implementation. The correct fix is a
compatibility facade that supports both old imports and new production APIs.

## Reference Application Roadmap

1. Expression Parser — arithmetic and AST correctness.
2. Variables — calculator memory and `let` declarations.
3. Input — interactive calculator prompts.
4. Conditions — operator dispatch.
5. Functions — `calculate(a, op, b)`.
6. Runtime — `panther run calculator.pan`.
7. Packaging — VS Code + CLI + examples + docs.

## Completion Definition

A phase is complete only after:

- implementation is present,
- local Kali execution succeeds,
- regression is run,
- failures are fixed,
- manifest is generated,
- report is generated,
- backup exists.
