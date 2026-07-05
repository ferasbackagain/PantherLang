panther main {
    print "=== Secure AI Chat ===";
    print "";

    let conn = db_open("chat_history.db");
    db_execute(conn, "CREATE TABLE IF NOT EXISTS messages (
        id INTEGER PRIMARY KEY,
        role TEXT,
        content TEXT,
        timestamp TEXT
    )");

    db_execute(conn, "INSERT OR IGNORE INTO messages VALUES (1, 'system', 'Secure AI Chat initialized', '2026-07-04 10:00:00')");
    let msg_count = db_query(conn, "SELECT COUNT(*) as cnt FROM messages");
    db_close(conn);

    print "Chat history database initialized: " + string(msg_count[0]["cnt"]) + " message(s)";
    print "";

    let providers = ai_supported_providers();
    print "Available AI providers: " + join(", ", providers);
    print "OpenAI available: " + string(ai_provider_available("openai"));
    print "Ollama available: " + string(ai_provider_available("ollama"));
    print "";

    let user_input = "Tell me about PantherLang security features";
    let sanitized = sanitize_html(user_input);
    print "User input: " + user_input;
    print "Sanitized (HTML-escaped): " + sanitized;
    print "";

    let response = ai_mock_chat(user_input);
    print "AI response (mock): " + response;
    print "";

    let response_hash = sha256(response);
    print "Message integrity hash: " + response_hash;
    print "";

    let rate_limit = 10;
    let remaining = 8;
    print "Rate limit: " + string(rate_limit) + " requests/min, " + string(remaining) + " remaining";
    print "";

    print "API endpoints:";
    print "  POST /chat     - Send message and get AI response";
    print "  GET  /history  - View chat history";
    print "  GET  /status   - System status";
    print "";
    print "Server starting on http://localhost:8080";
    print "=== Secure AI Chat Ready ===";
}

web {
    route GET "/" {
        return "<h1>Secure AI Chat</h1><p><a href='/status'>GET /status</a></p>";
    }

    route GET "/status" {
        let providers = ai_supported_providers();
        return json_encode({
            service: "Secure AI Chat",
            providers: providers,
            rate_limit: 10,
            status: "running"
        });
    }

    route GET "/history" {
        let conn = db_open("chat_history.db");
        let messages = db_query(conn, "SELECT * FROM messages ORDER BY id");
        db_close(conn);
        return json_encode(messages);
    }

    route POST "/chat" {
        let reply = ai_mock_chat("Secure chat message received");
        return json_encode({
            role: "assistant",
            content: sanitize_html(reply),
            timestamp: "2026-07-04 10:00:00"
        });
    }
}
