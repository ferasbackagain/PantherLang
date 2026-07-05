panther main {
    let hash = sha256("hello");
    print "sha256 len: " + string(len(hash));

    let hmac = hmac_sha256("key", "message");
    print "hmac len: " + string(len(hmac));

    let token = secure_token(16);
    print "token len: " + string(len(token));

    let cmp = secure_compare("abc", "abc");
    print "secure_compare same: " + string(cmp);

    let clean = sanitize_path("/safe", "/safe/subdir/file.txt");
    print "clean path: " + clean;

    let safe = sanitize_html("<script>alert(1)</script>");
    print "sanitized: " + safe;

    print "all security checks passed";
}
