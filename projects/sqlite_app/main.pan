panther main {
    print "=== PantherLang SQLite App ===";
    let conn = db_open(":memory:");
    db_execute(conn, "CREATE TABLE items (
        id INTEGER PRIMARY KEY,
        name TEXT,
        quantity INTEGER
    )");
    db_execute(conn, "INSERT INTO items VALUES (1, 'Widget', 10)");
    db_execute(conn, "INSERT INTO items VALUES (2, 'Gadget', 25)");
    db_execute(conn, "INSERT INTO items VALUES (3, 'Doohickey', 5)");
    let rows = db_query(conn, "SELECT * FROM items ORDER BY name");
    let i = 0;
    while i < len(rows) {
        let row = rows[i];
        print "Item: " + row["name"] + " x" + string(row["quantity"]);
        i = i + 1;
    }
    db_execute(conn, "UPDATE items SET quantity = 15 WHERE name = 'Widget'");
    let updated = db_query(conn, "SELECT quantity FROM items WHERE name = 'Widget'");
    print "Updated quantity: " + string(updated[0]["quantity"]);
    db_close(conn);
    print "=== SQLite App Complete ===";
}
