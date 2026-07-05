# PantherLang Security Guide

## Security Principles

PantherLang is designed as a security-native programming language:

1. **Safe defaults** — All features default to secure behavior
2. **No hardcoded secrets** — API keys read from environment variables only
3. **Defensive-only** — All cybersecurity features are defensive, never offensive
4. **Auditable** — AI tool calls, web requests, and agent actions can be logged
5. **Sandboxed** — Runtime can be constrained with resource limits

## Compiler Security

The `SecurityAnalyzer` detects:
- **S001**: Hardcoded secrets in variable declarations/assignments
- **S002**: Dangerous function names resembling unsafe APIs
- **S003**: Calls to potentially dangerous functions
- **S004**: String literals containing dangerous shell patterns
- **S005**: Hardcoded credentials in string literals

Usage (CLI):
```bash
panther check myfile.pan   # Runs syntax, semantic, AND security analysis
```

Usage (Python API):
```python
from compiler.security import SecurityAnalyzer
analyzer = SecurityAnalyzer()
diagnostics = analyzer.analyze(ast_node)
```

## Runtime Sandbox

The `Sandbox` provides resource limits:
```python
from compiler.security import Sandbox, ResourceLimits

limits = ResourceLimits(
    max_execution_time=30.0,
    max_file_size_mb=10,
    network_allowed=False,
    exec_allowed=False,
)
with Sandbox(limits) as sandbox:
    sandbox.check_file_read("/safe/path/file.txt")
    sandbox.check_time_limit()
```

## Web Security

The web platform includes:
- **Security Headers**: CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- **CSRF Protection**: Token-based cross-site request forgery prevention
- **Rate Limiting**: Sliding window per-client rate limits
- **CORS**: Origin validation with wildcard/subdomain support
- **Secure Cookies**: HttpOnly, Secure, SameSite attributes
- **JWT Validation**: Structure and expiry checking
- **XSS Prevention**: HTML sanitization, JSON output encoding

## AI Security

The AI platform includes:
- **Prompt Injection Detection**: 20+ patterns analyzed before processing
- **Audit Logging**: Full trace of tool calls with arguments and results
- **Output Validation**: Sensitive data (API keys, credit cards) redaction
- **Secure Agent**: Wraps Agent with injection blocking, sanitization, audit

## Package Manager Security

- **Integrity Checking**: SHA-256 checksums for packages
- **Typosquat Detection**: Levenshtein similarity against known packages
- **Lock File Validation**: Structure and version format verification
- **Manifest Security**: Detects insecure protocols and unsafe keywords

## Best Practices

1. Always use environment variables for secrets (never hardcode)
2. Enable sandbox for untrusted code execution
3. Enable rate limiting for production web servers
4. Enable prompt injection detection for AI agents
5. Validate lock files in CI/CD pipelines
6. Run security analysis on all source code
