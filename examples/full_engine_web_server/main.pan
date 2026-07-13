panther main {
    import panther.web as web;
    import panther.core as core;

    print "=== PantherLang Web Server ===";
    print "Starting server on http://127.0.0.1:8080";

    let server = web.server_create("127.0.0.1", 8080);

    // Home page
    web.get(server, "/", fn(req) { return "<html><body>"
        + "<h1>Hello from PantherLang Web</h1>"
        + "<p>This is served by the panther.web functional API.</p>"
        + "<ul>"
        + "<li><a href='/health'>Health Check</a></li>"
        + "<li><a href='/api/version'>API Version</a></li>"
        + "<li><a href='/users/feras'>User Profile</a></li>"
        + "<li><a href='/search?q=pantherlang'>Search</a></li>"
        + "</ul>"
        + "</body></html>"; });

    // Health check
    web.get(server, "/health", fn(req) { return {status: "ok", service: "panther-web", version: "1.1.9"}; });

    // API version
    web.get(server, "/api/version", fn(req) { return {version: "1.1.9", language: "PantherLang", engine: "panther.web"}; });

    // Path parameter example (uses req.params for structured access)
    web.get(server, "/users/{name}", fn(req) {
        let name = req.params["name"];
        return "<html><body>"
        + "<h1>User Profile</h1>"
        + "<p>User: " + name + "</p>"
        + "<p><a href='/'>Back to home</a></p>"
        + "</body></html>";
    });

    // Search endpoint (uses req.query for structured access)
    web.get(server, "/search", fn(req) {
        let q = req.query["q"];
        return {query: q, results: []};
    });

    // POST echo endpoint
    web.post(server, "/api/echo", fn(req) {
        return {echo: req["body"], method: "POST", ok: true};
    });

    // Start the server
    print "Routes registered. Starting server...";
    web.start(server);

    let info = web.server_info(server);
    print "Server running: " + core.to_string(info);
}
