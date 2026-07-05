# Lab 10: Database Platform

## Objectives
- Open an SQLite database with `db_open`
- Create tables and insert records with `db_execute`
- Query data with `db_query`
- Use parameterized queries to filter results safely

## Theory

PantherLang's SQLite stdlib functions:

- **db_open(path)**: Opens a database (`":memory:"` for in-memory)
- **db_execute(conn, sql[, params])**: Executes INSERT, UPDATE, DELETE, CREATE. Returns affected row count
- **db_query(conn, sql[, params])**: Runs SELECT queries, returns an array of row objects
- **db_close(conn)**: Closes the connection

Parameterized queries use `?` placeholders and an array of values:
```panther
let rows = db_query(conn, "SELECT * FROM t WHERE col = ?", ["value"]);
```

## Exercises

### Exercise 1: Create Tasks Table
**Task**: Open an in-memory database, create a `tasks` table with columns `id INTEGER`, `title TEXT`, `status TEXT`. Insert 3 records: one "active", one "active", one "done".
**Hint**: Use `db_open(":memory:")` then `db_execute(conn, "CREATE TABLE ...")`.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/10-lab.pan`

### Exercise 2: Query All Tasks
**Task**: Query all rows from `tasks` and print the total count and each task's title and status.
**Hint**: `db_query(conn, "SELECT * FROM tasks")` returns an array. Access fields with `row["title"]`.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/10-lab.pan`

### Exercise 3: Parameterized Filter
**Task**: Query only tasks where `status = "active"` using a parameterized query with `?` placeholder. Print the count and titles of active tasks.
**Hint**: `db_query(conn, "SELECT * FROM tasks WHERE status = ?", ["active"])`.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/10-lab.pan`

## Summary
You used PantherLang's SQLite functions to create tables, insert records, query all rows, and filter with parameterized queries.

## Further Reading
- Book Chapter 10: Database Platform
- examples/sqlite_crud/main.pan
