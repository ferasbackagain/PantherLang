# PantherLang Developer Edition v0.5

PantherLang is a native AI-ready systems language for building complete software systems from one source of truth.

This Developer Edition removes the previous patch confusion. Everything lives in one clean repository.

## Run

```bash
cd language
python3 panther.py doctor
python3 panther.py check examples/store.panther
python3 panther.py run examples/store.panther
```

Open:

```text
http://127.0.0.1:7777
```

API:

```text
GET  http://127.0.0.1:7777/products
POST http://127.0.0.1:7777/products
```

## POST Test

```bash
curl -X POST http://127.0.0.1:7777/products \
  -H "Content-Type: application/json" \
  -d '{"title":"Panther Laptop","price":1200,"stock":5}'
```

Then open `/products` again.

## What v0.5 Adds

- Stable folder structure
- Semantic model
- IR output
- In-memory data engine
- GET and POST API execution
- Runtime dashboard
- UI table rendering from data models
- Basic validation for required fields
- Security/capability documentation
- Test suite
- Helper scripts
