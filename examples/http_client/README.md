# PantherLang HTTP Client Example

Demonstrates PantherLang HTTP client operations:
- `http_get()` — fetch a URL
- `http_post()` — POST data to a URL

## Run

```bash
panther run examples/http_client/main.pan
```

## Expected Output

Makes GET and POST requests to httpbin.org and reports response sizes.
Returns null gracefully if network is unavailable.
