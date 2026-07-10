panther main {
    print("=== PantherLang Database CRUD + Transactions ===");

    // In-memory database for testing
    let db = db_open(":memory:");
    print("DB opened (in-memory)");

    // Create table
    db_execute(db, "CREATE TABLE accounts (id INTEGER PRIMARY KEY, name TEXT, balance REAL)");
    print("Table created");

    // === Transaction: successful transfer ===
    print("");
    print("[1] Successful transaction");
    db_begin(db);
    db_execute(db, "INSERT INTO accounts VALUES (1, 'Alice', 1000.00)");
    db_execute(db, "INSERT INTO accounts VALUES (2, 'Bob', 500.00)");
    db_commit(db);
    print("Two accounts created");

    let all = db_query(db, "SELECT COUNT(*) as cnt FROM accounts");
    print("Total accounts: " + to_string(all[0]["cnt"]));

    // === Read ===
    print("");
    print("[2] Read records");
    let alice = db_query(db, "SELECT * FROM accounts WHERE name = ?", ["Alice"]);
    print("Alice balance: " + to_string(alice[0]["balance"]));

    // === Update with transaction ===
    print("");
    print("[3] Transfer with commit");
    db_begin(db);
    db_execute(db, "UPDATE accounts SET balance = balance - 200 WHERE name = 'Alice'");
    db_execute(db, "UPDATE accounts SET balance = balance + 200 WHERE name = 'Bob'");
    db_commit(db);

    let alice2 = db_query(db, "SELECT balance FROM accounts WHERE name = 'Alice'");
    let bob2 = db_query(db, "SELECT balance FROM accounts WHERE name = 'Bob'");
    print("Alice: " + to_string(alice2[0]["balance"]));
    print("Bob:   " + to_string(bob2[0]["balance"]));

    // === Rollback ===
    print("");
    print("[4] Failed transfer (rolled back)");
    db_begin(db);
    db_execute(db, "UPDATE accounts SET balance = balance - 99999 WHERE name = 'Alice'");
    db_execute(db, "UPDATE accounts SET balance = balance + 99999 WHERE name = 'Bob'");
    db_rollback(db);

    let alice3 = db_query(db, "SELECT balance FROM accounts WHERE name = 'Alice'");
    let bob3 = db_query(db, "SELECT balance FROM accounts WHERE name = 'Bob'");
    print("After rollback:");
    print("Alice: " + to_string(alice3[0]["balance"]));
    print("Bob:   " + to_string(bob3[0]["balance"]));

    // === Delete ===
    print("");
    print("[5] Delete");
    db_execute(db, "DELETE FROM accounts WHERE name = 'Bob'");
    let remaining = db_query(db, "SELECT COUNT(*) as cnt FROM accounts");
    print("Remaining accounts: " + to_string(remaining[0]["cnt"]));

    db_close(db);
    print("");
    print("=== Database Demo Complete ===");
}
