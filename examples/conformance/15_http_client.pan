panther main {
    let response = http_get("https://httpbin.org/get");
    if response == null {
        print "HTTP GET returned null";
    } else {
        print "HTTP GET succeeded: " + string(len(response)) + " bytes";
    }
}
