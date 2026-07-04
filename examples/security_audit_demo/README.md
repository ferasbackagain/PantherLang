# Security Audit Demo

Demonstrates PantherLang's security-native direction with defensive-only behaviors.

**Allowed:**
- File path validation (allowlist-based)
- Secret/credential pattern detection
- Config audit
- Safe log analysis
- Secret redaction

**Forbidden (never implemented in PantherLang):**
- Exploit automation
- Credential theft
- Stealth / evasion
- Malware behavior
- Unauthorized scanning

## Run

```bash
panther run examples/security_audit_demo/main.pan
```

## Related Security Modules

- `compiler.security.SecurityAnalyzer` — Source code security diagnostics
- `compiler.security.Sandbox` — Runtime sandbox with resource limits
- `compiler.security.PromptInjectionDetector` — AI prompt security
- `compiler.security.OutputValidator` — Sensitive data redaction
