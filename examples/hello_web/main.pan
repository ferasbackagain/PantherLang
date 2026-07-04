panther main {
    print "PantherLang Web Template";
    print "Server: localhost:8080";
    print "Routes:";
    print "  GET /  -> <h1>Hello from PantherLang Web</h1>";
    print "  GET /about  -> <h1>About PantherLang</h1><p>Modern, Secure, AI-Native</p>";
    print "PantherLang web platform ready";
}

web {
    route GET "/" {
        return "<h1>Hello from PantherLang Web</h1>";
    }
    route GET "/about" {
        return "<h1>About PantherLang</h1><p>Modern, Secure, AI-Native</p>";
    }
    route GET "/health" {
        return { status: "ok", service: "panther-web" };
    }
}
