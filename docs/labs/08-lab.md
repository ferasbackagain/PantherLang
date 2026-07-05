# Lab 08: Security

## Objectives
- Hash data with `sha256`
- Generate cryptographically secure tokens with `secure_token`
- Sanitize file paths with `sanitize_path` to prevent traversal attacks
- Sanitize HTML with `sanitize_html` to prevent XSS

## Theory

PantherLang provides security functions in the stdlib:

- **sha256(data)**: Returns the hex-encoded SHA-256 hash of a string
- **hmac_sha256(key, message)**: Returns HMAC-SHA256 using the given key
- **secure_token(nbytes)**: Generates a random hex token (default 32 bytes, 64 hex chars)
- **secure_compare(a, b)**: Constant-time string comparison
- **sanitize_path(base, path)**: Resolves a user path against a base directory, raising an error if traversal is detected
- **sanitize_html(text)**: Escapes `<`, `>`, `&`, `"`, `'` to prevent XSS

These functions help follow the principle of never trusting user input.

## Exercises

### Exercise 1: Hash a Password
**Task**: Hash the string `"MyS3cur3P@ss!"` using SHA-256 and print the resulting hex hash.
**Hint**: `sha256(input)` returns a 64-character hex string.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/08-lab.pan`

### Exercise 2: Generate a Secure Token
**Task**: Generate a secure 32-byte token using `secure_token()`. Print the token and its length.
**Hint**: `secure_token(32)` generates a 64-character hex string (2 chars per byte). Use `len()` to confirm.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/08-lab.pan`

### Exercise 3: Sanitize a Path
**Task**: Use `sanitize_path("/safe/dir", "../etc/passwd")` and print the result or error.
**Hint**: `sanitize_path(base, path)` takes two arguments. It will raise an error on traversal.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/08-lab.pan`

### Exercise 4: Sanitize HTML
**Task**: Sanitize the string `"<script>alert('XSS')</script>"` using `sanitize_html()` and print the escaped result.
**Hint**: The output should replace `<` with `&lt;`, `>` with `&gt;`, etc.
**Verify**: Run `python -m cli.panther_cli run docs/labs/solutions/08-lab.pan`

## Summary
You used PantherLang's security stdlib to hash passwords, generate secure tokens, prevent path traversal, and sanitize HTML output.

## Further Reading
- Book Chapter 08: Security
- docs/SECURITY_GUIDE.md
