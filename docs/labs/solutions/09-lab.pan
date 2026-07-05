panther main {
    print "PantherLang Web Server starting...";
    print "Routes: GET /, GET /about, GET /health, GET /hello/:name, POST /echo";
}

web {
    route GET "/" {
        return "Home";
    }

    route GET "/about" {
        return {service: "PantherWeb", version: 1};
    }

    route GET "/health" {
        return {status: "ok"};
    }

    route GET "/hello/:name" {
        return "Hello, " + name + "!";
    }

    route POST "/echo" {
        return "Received: " + body;
    }
}
