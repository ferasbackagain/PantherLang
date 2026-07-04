# Chapter 10: Database Platform

## SQLite CRUD (PantherLang)

SQLite operations via stdlib functions:

```panther
let conn = db_open(":memory:");

db_execute(conn, "CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    age INTEGER
)");

db_execute(conn, "INSERT INTO users VALUES (1, 'Alice', 'a@x.com', 30)");
let rows = db_query(conn, "SELECT * FROM users");
print rows[0]["name"];    // "Alice"

db_execute(conn, "UPDATE users SET age = 31 WHERE name = 'Alice'");
db_execute(conn, "DELETE FROM users WHERE age < 30");
db_close(conn);
```

## ORM (Python API)

```python
from compiler.database.orm import SqliteEngine, Model, Column

engine = SqliteEngine(":memory:")
class User(Model):
    name = Column(str)
    age = Column(int)

engine.create_table(User)
user = User(name="Alice", age=30)
engine.insert(user)
```

## Query Builder

```python
from compiler.database.orm import QueryBuilder
qb = QueryBuilder(engine.table("users"))
qb.where("age > ?", [25]).order("name ASC").limit(10).select()
```

## Migrations

```python
from compiler.database.orm import Migration, migrate
Migration("001_create_users", "CREATE TABLE users (...)")
migrate(engine, migrations)
```
