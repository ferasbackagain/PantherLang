panther main {
    print "=== Lesson 09: Web Platform ===";
    print "";
    
    print "--- HTTP Server (Python API) ---";
    print "For full server control, use the Python API:";
    print "  from compiler.web.server import HttpServer";
    print "  server = HttpServer(host=\"0.0.0.0\", port=8080)";
    print "  server.get(\"/\", lambda req: {\"message\": \"Hello, Panther!\"})";
    print "  server.post(\"/data\", lambda req: {\"received\": req.body})";
    print "  server.start()";
    print "";
    
    print "--- Route Syntax in .pan Files ---";
    print "Route statements can appear directly in .pan programs:";
    print "";
    print "route GET \"/\" {";
    print "    return \"{ status: ok, message: Welcome to PantherLang }\";";
    print "}";
    print "";
    print "route GET \"/health\" {";
    print "    return \"{ status: healthy }\";";
    print "}";
    print "";
    print "route POST \"/echo\" {";
    print "    return \"{ echo: \" + request.body + \" }\";";
    print "}";
    print "";
    
    print "--- Run with: panther run --serve web_server.pan ---";
    print "";
    
    print "--- Security Middleware ---";
    print "Available middleware from compiler.web.security:";
    print "  SecurityHeaders: CSP, HSTS, X-Content-Type-Options";
    print "  CSRFProtection: HMAC-based token validation";
    print "  RateLimiter: Sliding window rate limiting";
    print "  CORSValidator: Origin validation";
    print "  XSSProtection: HTML sanitization";
    print "  SecureRequestHandler: Combined security middleware";
    print "";
    
    print "--- JSON API Pattern ---";
    print "  route GET \"/api/users\" {";
    print "    let users = db_query(conn, \"SELECT * FROM users\");";
    print "    return json_encode(users);";
    print "  }";
    print "";
    print "  route POST \"/api/users\" {";
    print "    let user = json_decode(request.body);";
    print "    db_execute(conn, \"INSERT INTO users (name) VALUES (?)\", [user[\"name\"]]);";
    print "    return \"{ created: true }\";";
    print "  }";
    print "";
    
    print "--- Web Development Best Practices ---";
    print "1. Use security middleware for all routes";
    print "2. Validate and sanitize all input";
    print "3. Use parameterized queries for database";
    print "4. Set appropriate security headers";
    print "5. Implement rate limiting";
    print "6. Use HTTPS in production";
    print "";
    
    print "=== Lesson 09 Complete ===";
}