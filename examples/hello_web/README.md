# Hello Web Example

Real PantherLang web application serving HTML pages with forms.

## Run

```bash
panther run --serve examples/hello_web/main.pan
```

Open http://localhost:8080 in your browser.

## Routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Home page with navigation and form |
| GET | `/about` | About page |
| POST | `/submit` | Form submission handler |
| GET | `/users/{name}` | Path parameter demo |
| GET | `/health` | Health check (JSON) |
