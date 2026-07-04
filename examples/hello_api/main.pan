panther main {
    print "PantherLang API Template";
    print "Server: localhost:8080";
    print "Routes:";
    print "  GET /health  -> API health check";
    print "  GET /api  -> API root";
    print "PantherLang API platform ready";
}

api {
    route GET "/health" {
        return { status: "ok", service: "panther-api" };
    }
    route GET "/api" {
        return { message: "hello from PantherLang API" };
    }
}
