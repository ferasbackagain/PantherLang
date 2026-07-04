# PantherLang CLI Guide

## Installation

```bash
pip install pantherlang
```

## Commands

### `panther doctor`
Verify that PantherLang is installed correctly:
```bash
panther doctor
```

### `panther new <type> <name>`
Create a new PantherLang project:
```bash
panther new console myapp
panther new web myapp
panther new api myapp
panther new ai myapp
```

### `panther run <file>`
Run a PantherLang source file:
```bash
panther run src/main.panther
```

### `panther build <file>`
Build a PantherLang source file to a shell artifact:
```bash
panther build src/main.panther --out build/output.sh
```

### `panther check <file>`
Validate a PantherLang source file:
```bash
panther check src/main.panther
```

### `panther fmt <file>`
Format (validate parse) a PantherLang source file:
```bash
panther fmt src/main.panther
```

### `panther version`
Show version information:
```bash
panther version
```

## Exit Codes

- `0`: Success
- `1`: General error / check failed
- `2`: Invalid usage / missing arguments
