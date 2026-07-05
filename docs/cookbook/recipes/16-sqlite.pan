panther main {
    let conn = db_open(":memory:");
    db_execute(conn, "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)");
    db_execute(conn, "INSERT INTO users (name, age) VALUES ('Alice', 30)");
    db_execute(conn, "INSERT INTO users (name, age) VALUES ('Bob', 25)");

    let rows = db_query(conn, "SELECT * FROM users ORDER BY name");
    print "users count: " + string(len(rows));
    print "first user: " + rows[0]["name"];

    let old = db_query(conn, "SELECT * FROM users WHERE age > ?", [26]);
    print "users over 26: " + string(len(old));

    db_close(conn);
    print "sqlite: PASS";
}
