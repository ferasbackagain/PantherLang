panther main {
    print "=== PantherLang SQLite CRUD ===";

    let conn = db_open(":memory:");

    db_execute(conn, "CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        age INTEGER
    )");

    db_execute(conn, "INSERT INTO users (name, email, age) VALUES ('Alice', 'alice@example.com', 30)");
    db_execute(conn, "INSERT INTO users (name, email, age) VALUES ('Bob', 'bob@example.com', 25)");
    db_execute(conn, "INSERT INTO users (name, email, age) VALUES ('Charlie', 'charlie@example.com', 35)");

    let rows = db_query(conn, "SELECT * FROM users ORDER BY age");
    print "Users (" + string(len(rows)) + " total):";
    print "  Alice age: " + string(rows[0]["age"]);
    print "  Bob age: " + string(rows[1]["age"]);
    print "  Charlie age: " + string(rows[2]["age"]);

    let n = db_execute(conn, "UPDATE users SET age = 31 WHERE name = 'Alice'");
    print "Updated " + string(n) + " row(s)";

    let updated = db_query(conn, "SELECT name, age FROM users WHERE name = 'Alice'");
    print "Alice new age: " + string(updated[0]["age"]);

    let deleted = db_execute(conn, "DELETE FROM users WHERE age < 30");
    print "Deleted " + string(deleted) + " user(s) under 30";

    let remaining = db_query(conn, "SELECT COUNT(*) as cnt FROM users");
    print "Remaining users: " + string(remaining[0]["cnt"]);

    db_close(conn);
    print "=== SQLite CRUD Demo Complete ===";
}
