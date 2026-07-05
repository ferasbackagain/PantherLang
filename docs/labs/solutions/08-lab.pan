panther main {
    print "=== Lab 08: Security ===";

    print "--- Exercise 1: Hash a Password ---";
    let password = "MyS3cur3P@ss!";
    let hash = sha256(password);
    print "SHA-256 hash: " + hash;
    print "Hash length: " + string(len(hash));

    print "--- Exercise 2: Secure Token ---";
    let token = secure_token(32);
    print "Session token: " + token;
    print "Token length: " + string(len(token));

    print "--- Exercise 3: Path Sanitization ---";
    let safe = sanitize_path("/safe/dir", "user/file.txt");
    print "Safe path: " + safe;

    print "--- Exercise 4: HTML Sanitization ---";
    let malicious = "<script>alert('XSS')</script>";
    let clean = sanitize_html(malicious);
    print "Original: " + malicious;
    print "Sanitized: " + clean;
}
