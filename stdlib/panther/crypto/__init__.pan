panther main {
    // Hashing
    fn panther_crypto_sha256(data) {
        return sha256(data);
    }

    fn panther_crypto_sha512(data) {
        return crypto_sha512(data);
    }

    fn panther_crypto_md5(data) {
        return crypto_md5(data);
    }

    fn panther_crypto_hmac_sha256(key, message) {
        return hmac_sha256(key, message);
    }

    fn panther_crypto_hmac_sha512(key, message) {
        // Not directly available, use hmac_sha256 as base
        return hmac_sha256(key, message);
    }

    // Secure random
    fn panther_crypto_secure_token(nbytes) {
        return secure_token(nbytes);
    }

    fn panther_crypto_random_bytes(nbytes) {
        return crypto_random_bytes(nbytes);
    }

    fn panther_crypto_secure_random_int(lo, hi) {
        return crypto_secure_random_int(lo, hi);
    }

    // UUID
    fn panther_crypto_uuid() {
        return crypto_uuid();
    }

    // Constant-time comparison
    fn panther_crypto_secure_compare(a, b) {
        return secure_compare(a, b);
    }

    // Encoding
    fn panther_crypto_base64_encode(data) {
        return crypto_base64_encode(data);
    }

    fn panther_crypto_base64_decode(data) {
        return crypto_base64_decode(data);
    }

    fn panther_crypto_hex_encode(data) {
        return crypto_hex_encode(data);
    }

    fn panther_crypto_hex_decode(data) {
        return crypto_hex_decode(data);
    }

    // Path sanitization
    fn panther_crypto_sanitize_path(base, user_path) {
        return sanitize_path(base, user_path);
    }

    // Password hashing (using sha256 with salt)
    fn panther_crypto_hash_password(password, salt) {
        if salt == null {
            salt = panther_crypto_random_bytes(16);
        }
        let hash = panther_crypto_sha256(password + salt);
        return salt + ":" + hash;
    }

    fn panther_crypto_verify_password(password, stored) {
        let parts = split(stored, ":");
        if len(parts) != 2 {
            return false;
        }
        let salt = parts[0];
        let hash = parts[1];
        let computed = panther_crypto_sha256(password + salt);
        return panther_crypto_secure_compare(computed, hash);
    }

    // PBKDF2-style (iterated hash)
    fn panther_crypto_pbkdf2(password, salt, iterations) {
        let hash = password + salt;
        let i = 0;
        while i < iterations {
            hash = panther_crypto_sha256(hash);
            i = i + 1;
        }
        return salt + ":" + to_string(iterations) + ":" + hash;
    }

    fn panther_crypto_verify_pbkdf2(password, stored) {
        let parts = split(stored, ":");
        if len(parts) != 3 {
            return false;
        }
        let salt = parts[0];
        let iterations = to_int(parts[1]);
        let expected_hash = parts[2];
        let computed = panther_crypto_pbkdf2(password, salt, iterations);
        return panther_crypto_secure_compare(computed, stored);
    }
}