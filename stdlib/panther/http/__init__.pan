panther main {
    // HTTP Client - using existing http_get, http_post, http_request, http_put, http_delete

    fn panther_http_get(url, timeout) {
        return http_get(url);
    }

    fn panther_http_post(url, data, timeout) {
        return http_post(url, data);
    }

    fn panther_http_put(url, data, timeout) {
        return http_put(url, data);
    }

    fn panther_http_delete(url, timeout) {
        return http_delete(url);
    }

    fn panther_http_request(method, url, data, timeout) {
        return http_request(method, url, data, timeout);
    }

    // Higher-level HTTP with structured response
    fn panther_http_fetch(url, method, data, timeout) {
        let result = http_request(method, url, data, timeout);
        if result.ok == true {
            return {ok: true, status: result.status, body: result.body};
        }
        return {ok: false, status: result.status, error: result.error};
    }

    fn panther_http_get_json(url, timeout) {
        let result = panther_http_fetch(url, "GET", "", timeout);
        if result.ok {
            return json_parse(result.body);
        }
        return null;
    }

    fn panther_http_post_json(url, data, timeout) {
        let result = panther_http_fetch(url, "POST", json_stringify(data), timeout);
        if result.ok {
            return json_parse(result.body);
        }
        return null;
    }

    fn panther_http_put_json(url, data, timeout) {
        let result = panther_http_fetch(url, "PUT", json_stringify(data), timeout);
        if result.ok {
            return json_parse(result.body);
        }
        return null;
    }

    fn panther_http_delete_json(url, timeout) {
        let result = panther_http_fetch(url, "DELETE", "", timeout);
        if result.ok {
            return json_parse(result.body);
        }
        return null;
    }

    // Simple status check
    fn panther_http_status_ok(status) {
        return status >= 200 && status < 300;
    }

    fn panther_http_status_error(status) {
        return status >= 400;
    }

    fn panther_http_status_redirect(status) {
        return status >= 300 && status < 400;
    }
}