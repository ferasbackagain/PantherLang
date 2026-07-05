# Capstone: Secure File Vault

## Level
Advanced

## Track
Security

## Prerequisites
- Academy Lessons 1-11
- Book Chapters 1-9

## Objective
Build a secure file vault that demonstrates file integrity hashing, authenticated messaging with HMAC, secure token generation, safe file access, and token verification.

## Requirements
1. Use `sha256` to compute file integrity hashes
2. Use `hmac_sha256` for authenticated message signing
3. Use `secure_token` to generate access keys
4. Use `sanitize_path` for safe file access
5. Use `write_file`/`read_file` for vault file operations
6. Use `secure_compare` to verify tokens
7. Print a security audit log showing all operations and their results

## Rubric
| Criteria | Points |
|----------|--------|
| Functionality | 40 |
| Security implementation | 20 |
| Audit logging | 20 |
| Documentation | 20 |

## Solution
Run: `python -m cli.panther_cli run docs/capstones/solutions/secure-file-vault.pan`

## Verification
Expected output:
```
=== Panther Secure File Vault ===
[VAULT] Initialized vault directory
[TOKEN] Generated master access token
[HASH] File integrity hash computed
[HMAC] Authenticated message signed
[WRITE] Encrypted content written to vault
[VERIFY] Token verification: PASS
[READ] Decrypted content read from vault
[INTEGRITY] Hash verification: PASS
Secure Audit Log:
  TOKEN: <64-char-hex>
  HASH: <64-char-hex>
  HMAC: <64-char-hex>
  TOKEN_MATCH: true
  FILE_OK: true
  INTEGRITY_OK: true
=== Secure File Vault Complete ===
```
