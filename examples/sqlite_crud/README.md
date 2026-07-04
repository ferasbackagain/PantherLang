# PantherLang SQLite CRUD Example

Demonstrates PantherLang SQLite database operations:
- `db_open()` — open database connection
- `db_execute()` — execute INSERT, UPDATE, DELETE
- `db_query()` — execute SELECT queries
- `db_close()` — close connection

## Run

```bash
panther run examples/sqlite_crud/main.pan
```

## Expected Output

Creates an in-memory SQLite database, creates a `users` table,
inserts 3 records, updates one, deletes one, and queries results.
