# PantherLang Models Specification

Models are semantic entities understood by the compiler, runtime, API engine, UI engine, and AI systems.

## Example

```panther
model Product {
    id: uuid
    title: string required
    price: decimal required
    stock: int = 0
}
```

## Rules
1. Model names use PascalCase.
2. Field names use snake_case.
3. Field types must be known Panther types or user-defined models.
4. Values are non-null by default.
5. Nullable fields use `?`.
6. Money and prices use `decimal`, not float.
