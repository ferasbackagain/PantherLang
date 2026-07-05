panther main {
    print "=== Lesson 10 Verification ===";
    print "";
    
    print "--- Test 1: Database CRUD ---";
    let conn = db_open(":memory:");
    
    db_execute(conn, "CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)");
    
    db_execute(conn, "INSERT INTO test (value) VALUES (?)", ["hello"]);
    db_execute(conn, "INSERT INTO test (value) VALUES (?)", ["world"]);
    
    let results = db_query(conn, "SELECT * FROM test");
    if len(results) == 2 { print "INSERT + SELECT: PASS"; } else { print "INSERT + SELECT: FAIL"; }
    
    if results[0]["value"] == "hello" && results[1]["value"] == "world" { print "Values correct: PASS"; } else { print "Values correct: FAIL"; }
    
    let single = db_query(conn, "SELECT * FROM test WHERE value = ?", ["hello"]);
    if len(single) == 1 && single[0]["value"] == "hello" { print "Parameterized query: PASS"; } else { print "Parameterized query: FAIL"; }
    
    db_execute(conn, "UPDATE test SET value = ? WHERE value = ?", ["updated", "hello"]);
    let updated = db_query(conn, "SELECT * FROM test WHERE value = ?", ["updated"]);
    if len(updated) == 1 { print "UPDATE: PASS"; } else { print "UPDATE: FAIL"; }
    
    db_execute(conn, "DELETE FROM test WHERE value = ?", ["world"]);
    let remaining = db_query(conn, "SELECT COUNT(*) as count FROM test");
    if remaining[0]["count"] == 1 { print "DELETE: PASS"; } else { print "DELETE: FAIL"; }
    
    db_close(conn);
    
    print "";
    print "=== All Lesson 10 Tests Complete ===";
}