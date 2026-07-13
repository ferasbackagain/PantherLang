panther main {
    print "=== PantherLang Web Engine Browser Demo ===";
    print "Use: panther run --serve examples/full_engine_browser_demo/main.pan";
    print "Then open http://127.0.0.1:8080 in your browser";
}

web {
    route GET "/" {
        let html = "<!DOCTYPE html><html><head><meta charset='UTF-8'>"
            + "<title>PantherLang Web Engine</title>"
            + "<style>"
            + "body { font-family: sans-serif; background: #0d1117; color: #c9d1d9; max-width: 800px; margin: 0 auto; padding: 2rem; }"
            + "h1 { color: #58a6ff; text-align: center; }"
            + ".card { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 1.5rem; margin: 1rem 0; }"
            + "a { color: #58a6ff; }"
            + "footer { text-align: center; color: #8b949e; margin-top: 2rem; }"
            + "</style></head><body>"
            + "<h1>PantherLang Web Engine</h1>"
            + "<p style='text-align: center; color: #8b949e;'>Built with PantherLang v1.1.9</p>"
            + "<div class='card'>"
            + "<p>This page is served by <strong>PantherLang Web Engine</strong>.</p>"
            + "<p>The server is backed by Python's <code>http.server.HTTPServer</code>.</p>"
            + "</div>"
            + "<div class='card'>"
            + "<h2>Endpoints</h2>"
            + "<ul>"
            + "<li><a href='/health'>GET /health</a> — Health check</li>"
            + "<li><a href='/api/version'>GET /api/version</a> — Version info</li>"
            + "<li><a href='/api/system'>GET /api/system</a> — System info</li>"
            + "<li><a href='/users/feras'>GET /users/{name}</a> — Path params</li>"
            + "</ul>"
            + "</div>"
            + "<footer><p>PantherLang v1.1.9 — Web Engine Demo</p></footer>"
            + "</body></html>";
        return html;
    }

    route GET "/health" {
        return {status: "ok", service: "panther-web-demo", version: "1.1.9"};
    }

    route GET "/api/version" {
        return {version: "1.1.9", language: "PantherLang", engine: "panther.web"};
    }

    route GET "/api/system" {
        return {host: "127.0.0.1", platform: "linux", arch: "x86_64", server: "PantherLang HttpServer", version: "1.1.9"};
    }

    route GET "/users/{name}" {
        return "<html><body>"
            + "<h1>User Profile</h1>"
            + "<p>User: " + name + "</p>"
            + "<p><a href='/'>Back to home</a></p>"
            + "</body></html>";
    }
}
