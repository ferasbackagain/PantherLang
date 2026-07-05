# Lab 18: Integration Project — Todo Web API

## Objectives
- Combine SQLite, web routing, JSON, and security in one application
- Create a todo list web API with persistent storage
- Implement user authentication with SHA-256 hashing
- Return JSON responses from web endpoints

## Theory
This lab integrates multiple PantherLang features into a single application:
- **SQLite** (`db_open`, `db_execute`, `db_query`, `db_close`) for persistent data storage
- **Web routing** (`web { route GET/POST ... }`) for HTTP endpoints
- **JSON** (`json_encode`) for structured API responses
- **SHA-256** (`sha256`) for secure password hashing
- **SQL injection protection**: use parameterized queries with `db_execute(conn, sql, [params])`

## Exercises

### Exercise 1: Create a todo list web app with SQLite backend
**Task**: Create a `todos` table and a `users` table. Seed with sample data. Expose a GET endpoint that returns all todos as JSON.
**Hint**: Use `db_open("todos.db")` and `CREATE TABLE IF NOT EXISTS`. Routes go in the `web {}` block.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/18-lab.pan`

### Exercise 2: Add user authentication with SHA-256
**Task**: Create a `users` table with `username` and `password_hash` columns. Insert a demo user with `sha256("securepass")`.
**Hint**: `sha256(data)` returns a hex string. Store the hash, not the plain password.
**Verify**: The solution prints the password hash and confirms user creation.

### Exercise 3: Return JSON responses
**Task**: Use `json_encode()` to serialize todo lists and user data for API responses.
**Hint**: `db_query()` returns an array of dicts — pass it directly to `json_encode()`.
**Verify**: The output shows todos formatted as a JSON array.

## Summary
You built a full-stack web API with database persistence, user authentication, and JSON responses — integrating PantherLang's web, database, security, and serialization features.

## Further Reading
- `examples/sqlite_crud/main.pan`
- `examples/hello_web/main.pan`
- `compiler/web/server.py` for route handling internals
