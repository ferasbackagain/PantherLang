panther main {
    print "=== Lesson 08: Security ===";
    print "";
    
    print "--- Security Diagnostics (S001-S005) ---";
    print "The PantherLang compiler detects security issues:";
    print "S001: Hardcoded secrets in string literals";
    print "S002: Dangerous function names (exec, eval, system)";
    print "S003: Dangerous function calls";
    print "S004: Dangerous shell command patterns";
    print "S005: Secret patterns in string values";
    print "";
    print "Run 'panther check <file>' to scan your code.";
    print "";
    
    print "--- Secret Detection ---";
    let api_key = "sk-1234567890abcdef";
    print "Example secret: " + api_key;
    print "This would trigger S001 if checked!";
    print "";
    
    print "--- Path Traversal Prevention ---";
    let safe_path = sanitize_path("/safe/base", "/safe/base/user/file.txt");
    print "Safe path: " + safe_path;
    print "Unsafe paths are blocked and raise an error (run panther check to detect)";
    print "";
    
    print "--- HTML Sanitization ---";
    let malicious = "<script>alert('xss')</script>";
    let sanitized = sanitize_html(malicious);
    print "Original: " + malicious;
    print "Sanitized: " + sanitized;
    print "";
    
    print "--- Secure Token Generation ---";
    let token = secure_token(32);
    print "Secure token (32 bytes): " + token;
    print "Length: " + to_string(len(token));
    print "";
    
    print "--- Constant-Time Comparison ---";
    let secret = "my-secret-token";
    let input1 = "my-secret-token";
    let input2 = "wrong-token";
    print "secure_compare(secret, correct): " + to_string(secure_compare(secret, input1));
    print "secure_compare(secret, wrong): " + to_string(secure_compare(secret, input2));
    print "";
    
    print "--- SHA256 Hashing ---";
    let password = "user-password-123";
    let hash = sha256(password);
    print "Password: " + password;
    print "SHA256: " + hash;
    print "";
    
    print "--- HMAC ---";
    let message = "authenticated message";
    let key = "secret-key";
    let hmac = hmac_sha256(key, message);
    print "Message: " + message;
    print "HMAC-SHA256: " + hmac;
    print "";
    
    print "--- Secure Coding Patterns ---";
    print "1. Never hardcode API keys - use environment variables";
    print "2. Always sanitize user input paths";
    print "3. Sanitize HTML output to prevent XSS";
    print "4. Use secure_compare for secret validation";
    print "5. Generate tokens with secure_token()";
    print "6. Hash passwords with sha256() + salt";
    print "7. Use HMAC for message authentication";
    print "";
    
    print "=== Lesson 08 Complete ===";
}