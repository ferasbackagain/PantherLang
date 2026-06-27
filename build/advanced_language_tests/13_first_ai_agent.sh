#!/usr/bin/env bash
set -euo pipefail
echo "PantherLang compiled artifact"
# DECLARE_AGENT: agent PantherSecurityAgent role reviewer permissions ["review", "message"]
# DECLARE_MEMORY: memory project remember "agent.goal" = "Analyze code security"
# DECLARE_INTENT: intent "Review this PantherLang program for security issues"
echo "First AI Agent written in PantherLang"
