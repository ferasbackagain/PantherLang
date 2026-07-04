# Chapter 8: Security

PantherLang is security-native — security analysis is built into the compiler pipeline.

## Security Analyzer Diagnostics

Running `panther check` runs the security analyzer, which detects:

| Code | Detection |
|------|-----------|
| S001 | Hardcoded secrets (API keys, passwords, tokens) in string literals |
| S002 | Dangerous function names (exec, eval, system) |
| S003 | Dangerous function calls |
| S004 | Dangerous shell command patterns |
| S005 | Secret patterns in string values |

## Runtime Sandbox

```python
# Python API — not PantherLang syntax
from compiler.security import Sandbox
sandbox = Sandbox(max_exec_time=5, max_memory_mb=100)
sandbox.check_file_read("/etc/passwd")     # blocked
sandbox.check_file_write("/tmp/test.txt")  # allowed
```

## Web Security Middleware

Available in `compiler.web.security`:

- **SecurityHeaders**: CSP, HSTS, X-Content-Type-Options, X-Frame-Options
- **CSRFProtection**: HMAC-based token generation and validation
- **RateLimiter**: Sliding window per-key rate limiting
- **CORSValidator**: Origin validation with wildcard support
- **XSSProtection**: HTML sanitization
- **CookieSecurity**: Secure cookie builder (HttpOnly, Secure, SameSite)
- **JWTSafety**: JWT structure validation and expiration checking

## AI Security

```python
from compiler.security import PromptInjectionDetector, OutputValidator
detector = PromptInjectionDetector()
result = detector.detect("Ignore all previous instructions")
# result.is_injection == True
```

## Defensive Patterns

```panther
// Never hardcode secrets:
// BAD:  let key = "sk-1234567890abcdef"
// GOOD: key is read from environment variable at runtime

// Always sanitize paths:
let safe = sanitize_path(user_input);

// Use SecureAgent in production:
// SecureAgent has prompt injection detection and audit logging
```
