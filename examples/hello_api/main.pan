panther main {
    print "PantherLang API Server starting...";
    print "Open http://localhost:8080/api in your browser";
}

api {
    route GET "/api" {
        return {
            message: "Hello from PantherLang API",
            version: "1.0",
            endpoints: [
                "GET /api",
                "GET /api/health",
                "POST /api/data",
                "PUT /api/data/{id}",
                "DELETE /api/data/{id}"
            ]
        };
    }
    route GET "/api/health" {
        return { status: "ok", service: "panther-api" };
    }
    route POST "/api/data" {
        return {
            ok: true,
            method: "POST",
            message: "Data received"
        };
    }
    route PUT "/api/data/{id}" {
        return {
            ok: true,
            method: "PUT",
            id: id,
            message: "Data updated"
        };
    }
    route DELETE "/api/data/{id}" {
        return {
            ok: true,
            method: "DELETE",
            id: id,
            message: "Data deleted"
        };
    }
}
