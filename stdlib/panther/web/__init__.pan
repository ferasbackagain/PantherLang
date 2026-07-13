panther main {
    // =====================================================
    // Request/Response data model
    // =====================================================
    struct Request {
        method: string,
        path: string,
        headers: object,
        query: object,
        body: any,
        params: object
    }

    struct Response {
        status: int,
        headers: object,
        body: any
    }

    // Server creation - creates a real HTTP server via Python backend
    fn panther_web_server_create(host, port) {
        return _web_server_create(host, port);
    }

    // Route registration
    fn panther_web_get(server, path, handler) {
        return _web_route_get(server, path, handler);
    }

    fn panther_web_post(server, path, handler) {
        return _web_route_post(server, path, handler);
    }

    fn panther_web_put(server, path, handler) {
        return _web_route_put(server, path, handler);
    }

    fn panther_web_delete(server, path, handler) {
        return _web_route_delete(server, path, handler);
    }

    fn panther_web_route(server, method, path, handler) {
        return _web_route_add(server, method, path, handler);
    }

    // Server start/stop - real operations
    fn panther_web_start(server) {
        return _web_server_start(server);
    }

    fn panther_web_stop(server) {
        return _web_server_stop(server);
    }

    fn panther_web_server_running(server) {
        return _web_server_running(server);
    }

    fn panther_web_server_port(server) {
        return _web_server_port(server);
    }

    // Response helpers
    fn panther_web_response_json(data) {
        return _web_response_json(data);
    }

    fn panther_web_response_html(html) {
        return _web_response_html(html);
    }

    fn panther_web_response_text(text) {
        return _web_response_text(text);
    }

    fn panther_web_response(data, status) {
        if status == null {
            return _web_response(data);
        }
        return _web_response_status(data, status);
    }

    fn panther_web_response_error(status, message) {
        return {status: status, error: message};
    }

    fn panther_web_response_redirect(url) {
        return {redirect: url};
    }

    fn panther_web_response_status(data, status) {
        return _web_response_status(data, status);
    }

    fn panther_web_response_object(data, status, headers) {
        if status == null {
            status = 200;
        }
        if headers == null {
            headers = {};
        }
        let resp = _web_response_status(data, status);
        resp["headers"] = headers;
        return resp;
    }

    // Request helpers
    fn panther_web_request_param(req, name, default) {
        let val = req.params[name];
        if val != null {
            return val;
        }
        if default != null {
            return default;
        }
        return null;
    }

    fn panther_web_request_query(req, name, default) {
        let val = req.query[name];
        if val != null {
            return val;
        }
        if default != null {
            return default;
        }
        return null;
    }

    fn panther_web_request_body(req) {
        let body = req["body"];
        if body != null {
            return body;
        }
        return "";
    }

    fn panther_web_request_header(req, name) {
        let headers = req["headers"];
        if headers != null {
            let val = headers[name];
            if val != null {
                return val;
            }
        }
        return null;
    }

    fn panther_web_request_method(req) {
        return req["method"];
    }

    fn panther_web_request_path(req) {
        return req["path"];
    }

    // Error handling
    fn panther_web_error_handler(server, status, handler) {
        return _web_error_handler(server, status, handler);
    }

    // CORS
    fn panther_web_cors(server, options) {
        return server;
    }

    // Health check
    fn panther_web_health_check() {
        return {status: "ok", timestamp: time()};
    }

    // Server info
    fn panther_web_server_info(server) {
        return {
            host: server._host,
            port: _web_server_port(server),
            running: _web_server_running(server)
        };
    }
}
