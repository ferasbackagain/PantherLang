# PantherLang Agent Guide

This document teaches AI coding agents how to work inside PantherLang projects.

## Identity

PantherLang is the official programming language of the Panther Ecosystem.

## File Extensions

- `.panther`
- `.pan`

## Project Manifest

Every PantherLang project should contain:

```text
panther.toml
src/main.panther
```

## Common Commands

```bash
panther run
panther build
panther test
panther deploy
```

Current R3 VS Code integration also supports:

- PantherLang: New Project
- PantherLang: Run Current File
- PantherLang: Build Project
- PantherLang: Debug Project
- PantherLang: Doctor

## Project Types

- console
- web
- api
- ai

## Agent Behavior Rules

When asked to create PantherLang code:

1. Prefer creating a valid PantherLang project structure.
2. Use `panther.toml` as the project source of truth.
3. Put executable source in `src/main.panther`.
4. Include README instructions.
5. Include `.vscode/tasks.json` and `.vscode/launch.json` when building project templates.
6. Do not invent external package names unless requested.
7. For web/API examples, keep routes minimal and readable.
8. For AI examples, do not hard-code API keys.

## Minimal Console Example

```panther
panther main {
    print("Hello Panther")
}
```

## Minimal API Example

```panther
panther api {
    get "/health" {
        return { "status": "ok" }
    }
}
```
