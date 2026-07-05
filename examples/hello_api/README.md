# Hello API Example

Real PantherLang JSON API with GET, POST, PUT, and DELETE endpoints.

## Run

```bash
panther run --serve examples/hello_api/main.pan
```

Open http://localhost:8080/api in your browser or use curl.

## Routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api` | API root with endpoint list |
| GET | `/api/health` | Health check |
| POST | `/api/data` | Create data |
| PUT | `/api/data/{id}` | Update data by ID |
| DELETE | `/api/data/{id}` | Delete data by ID |

## Example requests

```bash
# GET
curl http://localhost:8080/api

# POST
curl -X POST http://localhost:8080/api/data

# PUT
curl -X PUT http://localhost:8080/api/data/42

# DELETE
curl -X DELETE http://localhost:8080/api/data/42
```
