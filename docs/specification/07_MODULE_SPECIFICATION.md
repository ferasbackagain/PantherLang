# PantherLang Module Specification

## Import Syntax

```
import "module_name";
import module_name;
import module.path.name;
import module.path.name as alias;
```

## Module Resolution

Modules are resolved by:

1. **Built-in stdlib**: If the module name matches a built-in standard library
   module, it is loaded from `compiler.stdlib`.

2. **File path**: The module name is converted to a file path and resolved
   relative to the importing file's directory or the project root.

3. **Package registry**: If not found locally, the package manager attempts
   to resolve from the registry.

## Name Binding

```
import math;           → Available as `math`
import std.json;       → Available as `json`
import core.utils as u; → Available as `u`
```

## Standard Library Modules

All stdlib functions are registered globally in the runtime environment.
They can be called without explicit import:

```
print len("hello");
print sqrt(16);
```

## Current Limitations

- Module resolution from `panther.toml` manifest is not fully implemented
- Import statements are parsed but module loading is minimal
- Package registry resolution requires the package manager CLI
