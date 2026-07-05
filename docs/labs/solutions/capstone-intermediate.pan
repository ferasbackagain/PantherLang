panther main {
    print "=== Library Management API ===";
    print "";

    let conn = db_open("library.db");
    db_execute(conn, "CREATE TABLE IF NOT EXISTS books (
        id INTEGER PRIMARY KEY,
        title TEXT,
        author TEXT,
        year INTEGER,
        isbn TEXT UNIQUE
    )");

    db_execute(conn, "INSERT OR IGNORE INTO books VALUES (1, 'PantherLang Guide', 'Alice', 2025, '978-1-1111-1111-1')");
    db_execute(conn, "INSERT OR IGNORE INTO books VALUES (2, 'Advanced PantherLang', 'Bob', 2026, '978-2-2222-2222-2')");
    db_execute(conn, "INSERT OR IGNORE INTO books VALUES (3, 'Web Development with PantherLang', 'Alice', 2025, '978-3-3333-3333-3')");
    db_execute(conn, "INSERT OR IGNORE INTO books VALUES (4, 'Data Structures in PantherLang', 'Charlie', 2026, '978-4-4444-4444-4')");
    db_execute(conn, "INSERT OR IGNORE INTO books VALUES (5, 'AI Applications', 'Alice', 2025, '978-5-5555-5555-5')");

    let books = db_query(conn, "SELECT * FROM books");
    db_close(conn);

    print "Library initialized with " + string(len(books)) + " books";
    print "";

    let base = "library";
    let user_path = "books";
    let safe_path = sanitize_path(base, user_path);
    print "Sanitized path: " + safe_path;
    print "";

    let books_json = json_encode(books);
    print "Books collection as JSON:";
    print books_json;
    print "";

    print "API endpoints:";
    print "  GET  /books         - List all books";
    print "  GET  /books/search  - Search books (query params)";
    print "  POST /books         - Add a new book";
    print "  PUT  /books/:id     - Update a book";
    print "  DEL  /books/:id     - Delete a book";
    print "";
    print "Server starting on http://localhost:8080";
    print "=== Library API Ready ===";
}

web {
    route GET "/" {
        return "<h1>Library Management API</h1><p><a href='/books'>GET /books</a></p>";
    }

    route GET "/books" {
        let conn = db_open("library.db");
        let books = db_query(conn, "SELECT * FROM books ORDER BY title");
        db_close(conn);
        return json_encode(books);
    }

    route POST "/books" {
        return json_encode({status: "ok", message: "Book added (stub)"});
    }
}
