panther main {
    print "Testing HTTP functions";
    let response = http_get("https://httpbin.org/get");
    print "GET response received, len: " + string(len(response));
    let post_resp = http_post("https://httpbin.org/post", "{\"test\": true}");
    print "POST response received, len: " + string(len(post_resp));
    print "HTTP functions work";
}
