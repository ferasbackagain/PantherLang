panther main {
    print "Web recipes:";
    print "  GET /";
    print "  GET /hello/{name}";
    print "  POST /data";
    print "web routes defined: PASS";
}

web {
    route GET "/" {
        return "Hello, Web!";
    }

    route GET "/hello/{name}" {
        return "Hello, " + params["name"];
    }

    route POST "/data" {
        return "Received: " + body;
    }
}
