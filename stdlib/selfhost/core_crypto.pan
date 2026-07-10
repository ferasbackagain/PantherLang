panther main {
    fn sha256(text) {
        return crypto_sha256(text);
    }

    fn sha512(text) {
        return crypto_sha512(text);
    }

    fn md5(text) {
        return crypto_md5(text);
    }

    fn hmac_sha256(key, message) {
        return crypto_hmac_sha256(key, message);
    }

    fn uuid() {
        return crypto_uuid();
    }

    fn random_bytes(n) {
        return crypto_random_bytes(n);
    }

    fn random_int(lo, hi) {
        return crypto_secure_random_int(lo, hi);
    }

    fn base64_encode(text) {
        return crypto_base64_encode(text);
    }

    fn base64_decode(text) {
        return crypto_base64_decode(text);
    }

    fn hex_encode(text) {
        return crypto_hex_encode(text);
    }

    fn hex_decode(text) {
        return crypto_hex_decode(text);
    }
}
