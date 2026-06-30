# PantherLang Grammar Quick Reference

This is a practical quick reference for AI agents and developers.

## Program Entry

```panther
panther main {
    print("Hello Panther")
}
```

## Tests

```panther
panther test "feature works" {
    assert true
}
```

## Web Route Pattern

```panther
panther web {
    route "/" {
        return "Hello"
    }
}
```

## API Route Pattern

```panther
panther api {
    get "/health" {
        return { "status": "ok" }
    }
}
```

## AI App Pattern

```panther
panther ai {
    prompt = "Build safely"
    print("AI-ready app")
}
```

## Naming Conventions

- Project names: lowercase words with dashes.
- Source directory: `src/`.
- Entry file: `src/main.panther`.
- Tests directory: `tests/`.
