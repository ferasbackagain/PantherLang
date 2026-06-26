# PantherLang Architecture

Core pipeline:

```text
Source → Tokenizer → Parser → AST → Semantic Model → IR → Runtime
```

v0.5 executes from the Semantic Model.
