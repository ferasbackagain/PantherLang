panther main {
    let conn = db_open(":memory:");
    db_execute(conn, "CREATE TABLE users (id INTEGER, name TEXT, age INTEGER)");
    db_execute(conn, "INSERT INTO users VALUES (1, 'Alice', 30)");
    db_execute(conn, "INSERT INTO users VALUES (2, 'Bob', 25)");
    let rows = db_query(conn, "SELECT * FROM users ORDER BY age");
    print len(rows);
    print rows[0]["name"];
    print rows[1]["name"];
    db_close(conn);
}
