panther main {
    print "=== Panther URL Shortener ===";

    let conn = db_open(":memory:");
    print "[DATABASE] In-memory SQLite initialized";

    db_execute(conn, "CREATE TABLE IF NOT EXISTS url_mappings (
        id INTEGER PRIMARY KEY,
        short_code TEXT UNIQUE,
        original_url TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
    )");
    print "[TABLE] Created table: url_mappings";

    let urls = ["https://example.com/docs", "https://pantherlang.org", "https://github.com", "https://example.com/docs"];
    let codes = [];
    let i = 0;
    while i < len(urls) {
        let url = urls[i];
        let hash = sha256(url);
        let code = substring(hash, 0, 8);

        let existing = db_query(conn, "SELECT short_code FROM url_mappings WHERE original_url = ?", [url]);
        if len(existing) > 0 {
            print "[DUPLICATE] URL already exists: " + existing[0]["short_code"];
        } else {
            db_execute(conn, "INSERT INTO url_mappings (short_code, original_url) VALUES (?, ?)", [code, url]);
            print "[INSERT] Short code '" + code + "' -> " + url;
            let n = array_push(codes, code);
        }
        i = i + 1;
    }

    let lookup_code = codes[0];
    let rows = db_query(conn, "SELECT original_url FROM url_mappings WHERE short_code = ?", [lookup_code]);
    if len(rows) > 0 {
        print "[LOOKUP] " + lookup_code + " -> " + rows[0]["original_url"];
    }

    let all = db_query(conn, "SELECT * FROM url_mappings ORDER BY id");
    print "All Mappings:";
    let j = 0;
    while j < len(all) {
        let r = all[j];
        print "  " + r["short_code"] + " -> " + r["original_url"];
        j = j + 1;
    }

    db_close(conn);
    print "=== URL Shortener Complete ===";
}
