# PantherLang Project Conventions

## Standard Layout

```text
my-project/
  panther.toml
  README.md
  .gitignore
  src/
    main.panther
  tests/
  docs/
  .vscode/
    settings.json
    tasks.json
    launch.json
```

## Manifest

```toml
[project]
name = "my-project"
type = "console"
version = "0.1.0"
language = "panther"

[run]
main = "src/main.panther"
```

## VS Code

Use command palette:

- `PantherLang: New Project`
- `PantherLang: Run Current File`
- `PantherLang: Build Project`
- `PantherLang: Debug Project`
