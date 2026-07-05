panther main {
    print "=== Lesson 10: Database Platform ===";
    print "";
    
    print "--- SQLite CRUD (PantherLang) ---";
    print "SQLite operations via stdlib functions:";
    print "";
    print "let conn = db_open(\":memory:\");";
    print "";
    print "db_execute(conn, \"CREATE TABLE users (";
    print "    id INTEGER PRIMARY KEY,";
    print "    name TEXT NOT NULL,";
    print "    email TEXT,";
    print "    age INTEGER";
    print ")\");";
    print "";
    print "db_execute(conn, \"INSERT INTO users VALUES (1, 'Alice', 'a@x.com', 30)\");";
    print "let rows = db_query(conn, \"SELECT * FROM users\");";
    print "print rows[0][\"name\"];  // \"Alice\"";
    print "";
    print "db_execute(conn, \"UPDATE users SET age = 31 WHERE name = 'Alice'\");";
    print "db_execute(conn, \"DELETE FROM users WHERE age < 30\");";
    print "db_close(conn);";
    print "";
    
    print "--- ORM (Python API) ---";
    print "For object-oriented database access:";
    print "";
    print "from compiler.database.orm import SqliteEngine, Model, Column";
    print "";
    print "engine = SqliteEngine(\":memory:\")";
    print "class User(Model):";
    print "    name = Column(str)";
    print "    age = Column(int)";
    print "";
    print "engine.create_table(User)";
    print "user = User(name=\"Alice\", age=30)";
    print "engine.insert(user)";
    print "";
    
    print "--- Query Builder ---";
    print "";
    print "from compiler.database.orm import QueryBuilder";
    print "qb = QueryBuilder(engine.table(\"users\"))";
    print "qb.where(\"age > ?\", [25]).order(\"name ASC\").limit(10).select()";
    print "";
    
    print "--- Migrations ---";
    print "";
    print "from compiler.database.orm import Migration, migrate";
    print "Migration(\"001_create_users\", \"CREATE TABLE users (...)\")";
    print "migrate(engine, migrations)";
    print "";
    
    print "--- Database Best Practices ---";
    print "1. Always use parameterized queries (? placeholders)";
    print "2. Close connections with db_close()";
    print "3. Use transactions for multiple operations";
    print "4. Handle errors gracefully";
    print "5. Use migrations for schema changes";
    print "";
    
    print "=== Lesson 10 Complete ===";
}