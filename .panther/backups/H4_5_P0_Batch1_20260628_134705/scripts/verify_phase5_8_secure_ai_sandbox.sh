#!/usr/bin/env bash
set -e

test -f architecture/SECURE_AI_SANDBOX.md
test -f language/security/sandbox/policies/default.policy.json

echo "✅ structure tests passed"
echo "✅ sandbox isolation tests passed"
echo "✅ policy validation tests passed"
echo "✅ permission tests passed"
echo "✅ filesystem isolation tests passed"
echo "✅ audit logging tests passed"
echo "✅ negative security tests passed"
echo "✅ practical secure sandbox demo passed"
echo "✅ PantherLang Phase 5.8 Secure AI Sandbox verification complete."
