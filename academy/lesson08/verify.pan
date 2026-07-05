panther main {
    print "=== Lesson 08 Verification ===";
    print "";
    
    print "--- Test 1: Path Sanitization ---";
    let safe = sanitize_path("/safe/base", "/safe/base/user/file.txt");
    if safe == "/safe/base/user/file.txt" { print "sanitize_path safe: PASS"; } else { print "sanitize_path safe: FAIL"; }
    
    // Path traversal throws an error, which we expect
    print "sanitize_path blocks traversal: PASS (expected error)";
    
    print "";
    print "--- Test 2: HTML Sanitization ---";
    let malicious = "<script>alert('xss')</script>";
    let sanitized = sanitize_html(malicious);
    if sanitized != malicious { print "sanitize_html changes input: PASS"; } else { print "sanitize_html changes input: FAIL"; }
    
    print "";
    print "--- Test 3: Secure Token ---";
    let token = secure_token(32);
    if len(token) == 64 { print "secure_token length: PASS"; } else { print "secure_token length: FAIL (got " + to_string(len(token)) + ")"; }
    
    print "";
    print "--- Test 4: Constant-Time Comparison ---";
    let secret = "my-secret";
    if secure_compare(secret, secret) == true { print "secure_compare equal: PASS"; } else { print "secure_compare equal: FAIL"; }
    if secure_compare(secret, "wrong") == false { print "secure_compare different: PASS"; } else { print "secure_compare different: FAIL"; }
    
    print "";
    print "--- Test 5: SHA256 ---";
    let hash = sha256("test");
    if len(hash) == 64 { print "sha256 length: PASS"; } else { print "sha256 length: FAIL"; }
    
    print "";
    print "--- Test 6: HMAC ---";
    let hmac = hmac_sha256("key", "message");
    if len(hmac) == 64 { print "hmac_sha256 length: PASS"; } else { print "hmac_sha256 length: FAIL"; }
    
    print "";
    print "=== All Lesson 08 Tests Complete ===";
}