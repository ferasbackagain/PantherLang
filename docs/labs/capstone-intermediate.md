# Capstone: Library Management API (Intermediate)

## Objectives
- Build a RESTful web API with SQLite persistence
- Implement CRUD operations for library books
- Search books by title or author
- Return JSON responses and sanitize file paths

## Theory
A library management API combines web routing, database operations, and data serialization. PantherLang's `web {}` block defines HTTP endpoints, while SQLite provides persistent storage. The `sanitize_path()` function ensures file operations stay within allowed directories.

## Exercises

### Exercise 1: Book CRUD with SQLite
**Task**: Create a `books` table with `id`, `title`, `author`, `year`, `isbn`. Seed with 5 books. Expose `GET /books` to list all books as JSON.
**Hint**: Use `db_open("library.db")`, `CREATE TABLE IF NOT EXISTS`, and `INSERT OR IGNORE`.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/capstone-intermediate.pan`

### Exercise 2: Search by title or author
**Task**: Add a `GET /books/search` route that queries books by title or author. Use parameterized queries for safety.
**Hint**: `db_query(conn, "SELECT * FROM books WHERE title LIKE ?", ["%" + query + "%"])`
**Verify**: The solution shows all seeded books ordered by title.

### Exercise 3: Path sanitization and JSON responses
**Task**: Use `sanitize_path()` to safely resolve a "books" data directory. Return all API responses as JSON with `json_encode()`.
**Hint**: `sanitize_path(base, user_path)` prevents directory traversal. `json_encode()` converts arrays/dicts to JSON strings.
**Verify**: The output shows the sanitized path and the books collection as a JSON array.

## Summary
You built a RESTful Library Management API with CRUD operations, search, path sanitization, and JSON responses using PantherLang's web, database, and security features.

## Further Reading
- `examples/sqlite_crud/main.pan`
- `examples/hello_web/main.pan`
- `compiler/web/server.py`
