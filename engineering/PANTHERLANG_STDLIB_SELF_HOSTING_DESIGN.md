# PantherLang Stdlib Self-Hosting Design

## Phase 1 model

Self-hosted stdlib source lives under:

```text
stdlib/selfhost/*.pan
```

Each file is an ordinary PantherLang source container. The loader extracts the
statements inside the first top-level block and injects them into user top-level
blocks before parsing and execution.

## Why this design

The current parser accepts top-level blocks such as `panther main { ... }`, not
top-level free functions. Injecting stdlib declarations into the user block
preserves the current grammar while allowing real `.pan` stdlib logic to run.

## Runtime relationship

```text
User source
→ apply_selfhosted_stdlib(source)
→ lex/parse/check/run
```

Host primitives remain Python-backed in Phase 1. Pure policy/logic functions move
to PantherLang `.pan` files.

## Phase 2 direction

Replace ad-hoc host-backed builtins with a formal Host ABI and allowlisted
capabilities.
