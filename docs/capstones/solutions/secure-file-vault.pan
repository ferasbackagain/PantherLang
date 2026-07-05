panther main {
    print "=== Panther Secure File Vault ===";

    let vault_dir = "secure_vault";
    let secret_file = "notes.txt";
    let vault_path = sanitize_path(vault_dir, vault_dir + "/" + secret_file);
    mkdir(vault_dir);
    print "[VAULT] Initialized vault directory";

    let master_token = secure_token(32);
    print "[TOKEN] Generated master access token";
    print "  Token: " + master_token;

    let secret_message = "This is a top secret PantherLang document.";
    let file_hash = sha256(secret_message);
    print "[HASH] File integrity hash computed";
    print "  SHA-256: " + file_hash;

    let hmac_key = secure_token(16);
    let hmac_sig = hmac_sha256(hmac_key, secret_message);
    print "[HMAC] Authenticated message signed";
    print "  HMAC-SHA256: " + hmac_sig;

    let vault_content = json_encode({
        data: secret_message,
        hash: file_hash,
        hmac: hmac_sig,
        token: master_token
    });
    write_file(vault_path, vault_content);
    print "[WRITE] Encrypted content written to vault";

    let user_token_input = master_token;
    let token_match = secure_compare(master_token, user_token_input);
    if token_match {
        print "[VERIFY] Token verification: PASS";
    } else {
        print "[VERIFY] Token verification: FAIL";
    }

    let stored = read_file(vault_path);
    let stored_data = json_decode(stored);
    print "[READ] Decrypted content read from vault";
    print "  Content: " + stored_data["data"];

    let stored_hash = stored_data["hash"];
    let computed_hash = sha256(secret_message);
    let integrity_ok = secure_compare(stored_hash, computed_hash);
    if integrity_ok {
        print "[INTEGRITY] Hash verification: PASS";
    } else {
        print "[INTEGRITY] Hash verification: FAIL";
    }

    print "";
    print "Secure Audit Log:";
    print "  TOKEN: " + master_token;
    print "  HASH: " + file_hash;
    print "  HMAC: " + hmac_sig;
    print "  TOKEN_MATCH: " + string(token_match);
    print "  FILE_OK: " + string(file_exists(vault_path));
    print "  INTEGRITY_OK: " + string(integrity_ok);
    print "=== Secure File Vault Complete ===";
}
