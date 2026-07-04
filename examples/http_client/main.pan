panther main {
    print "=== PantherLang HTTP Client ===";

    let response = http_get("https://httpbin.org/get");
    if response == null {
        print "HTTP GET returned null (network may be unavailable)";
    } else {
        print "HTTP GET succeeded: " + string(len(response)) + " bytes";
    }

    let post_resp = http_post("https://httpbin.org/post", "{\"hello\": \"world\"}");
    if post_resp == null {
        print "HTTP POST returned null (network may be unavailable)";
    } else {
        print "HTTP POST succeeded: " + string(len(post_resp)) + " bytes";
    }

    print "=== HTTP Client Demo Complete ===";
}
