panther main {
    print "=== Lab 10: Database Platform ===";

    print "--- Exercise 1: Create and Insert ---";
    let conn = db_open(":memory:");
    db_execute(conn, "CREATE TABLE tasks (id INTEGER, title TEXT, status TEXT)");
    db_execute(conn, "INSERT INTO tasks VALUES (1, 'Learn Panther', 'active')");
    db_execute(conn, "INSERT INTO tasks VALUES (2, 'Build an app', 'active')");
    db_execute(conn, "INSERT INTO tasks VALUES (3, 'Review code', 'done')");
    print "Table created with 3 records.";

    print "--- Exercise 2: Query All Tasks ---";
    let all = db_query(conn, "SELECT * FROM tasks");
    print "Total tasks: " + string(len(all));
    for i in 0..2 {
        let task = all[i];
        print "  Task " + string(task["id"]) + ": " + task["title"] + " [" + task["status"] + "]";
    }

    print "--- Exercise 3: Parameterized Filter ---";
    let active = db_query(conn, "SELECT * FROM tasks WHERE status = ?", ["active"]);
    print "Active tasks: " + string(len(active));
    for i in 0..1 {
        print "  " + active[i]["title"];
    }

    db_close(conn);
    print "Database closed.";
}
