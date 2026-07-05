panther main {
    print "=== Lab 18: Integration Project ===";
    print "";

    let conn = db_open("todos.db");
    db_execute(conn, "CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        username TEXT UNIQUE,
        password_hash TEXT
    )");
    db_execute(conn, "CREATE TABLE IF NOT EXISTS todos (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        title TEXT,
        completed INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )");

    let hash = sha256("securepass");
    db_execute(conn, "INSERT OR IGNORE INTO users (id, username, password_hash) VALUES (1, 'admin', ?)", [hash]);
    db_execute(conn, "INSERT OR IGNORE INTO todos (id, user_id, title, completed) VALUES (1, 1, 'Learn PantherLang', 0)");
    db_execute(conn, "INSERT OR IGNORE INTO todos (id, user_id, title, completed) VALUES (2, 1, 'Build a web app', 1)");
    db_execute(conn, "INSERT OR IGNORE INTO todos (id, user_id, title, completed) VALUES (3, 1, 'Write tests', 0)");

    let users = db_query(conn, "SELECT * FROM users");
    let todos = db_query(conn, "SELECT * FROM todos");
    db_close(conn);

    print "Database initialized with " + string(len(users)) + " user(s) and " + string(len(todos)) + " todo(s)";
    print "";

    print "User passwords secured with SHA-256";
    print "  Hash of 'securepass': " + hash;
    print "";

    let todo_json = json_encode(todos);
    print "Todos as JSON:";
    print todo_json;
    print "";

    print "Server endpoints:";
    print "  GET  /         - API info";
    print "  GET  /todos    - List all todos (JSON)";
    print "  POST /todos    - Create a todo";
    print "";
    print "Server starting on http://localhost:8080";
    print "=== Lab 18 Ready ===";
}

web {
    route GET "/" {
        return "<h1>Todo API</h1><p><a href='/todos'>GET /todos</a> - List all todos</p>";
    }

    route GET "/todos" {
        let conn = db_open("todos.db");
        let todos = db_query(conn, "SELECT * FROM todos");
        db_close(conn);
        return json_encode(todos);
    }

    route POST "/todos" {
        return json_encode({status: "ok", message: "Todo created (stub)"});
    }
}
