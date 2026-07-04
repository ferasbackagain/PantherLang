from __future__ import annotations

import time
from typing import Any

from compiler.security.ai_security import (
    AuditEntry,
    OutputValidator,
    PromptInjectionDetector,
    ToolCallAudit,
)

from .agents import Agent
from .providers import AIProvider


class SecureAgent(Agent):
    def __init__(
        self,
        provider: AIProvider,
        system_prompt: str = "",
        agent_id: str = "",
        enable_prompt_injection_detection: bool = True,
        enable_output_sanitization: bool = True,
        enable_audit: bool = True,
    ) -> None:
        super().__init__(provider, system_prompt)
        self._agent_id = agent_id or f"agent-{id(self)}"
        self._injection_detector = PromptInjectionDetector() if enable_prompt_injection_detection else None
        self._output_validator = OutputValidator() if enable_output_sanitization else None
        self._audit = ToolCallAudit() if enable_audit else None

    def run(self, prompt: str) -> str:
        if self._injection_detector:
            result = self._injection_detector.analyze(prompt)
            if result.detected:
                return f"[SECURITY] Potential prompt injection detected (score: {result.score:.2f})"

        content = super().run(prompt)

        if self._output_validator:
            if self._output_validator.contains_sensitive_data(content):
                content = self._output_validator.sanitize_output(content)

        return content

    def run_with_audit(self, prompt: str) -> tuple[str, list[AuditEntry]]:
        result = self.run(prompt)
        return result, (self._audit.get_log() if self._audit else [])

    def register_tool(self, tool: Any) -> None:
        original_tool = tool
        if hasattr(tool, "fn"):
            original_fn = tool.fn
            def _safe_fn(*args: Any, **kwargs: Any) -> str:
                return original_fn(*args, **kwargs)
            tool.fn = _safe_fn
        super().register_tool(tool)

    def get_audit_log(self) -> list[AuditEntry]:
        return self._audit.get_log() if self._audit else []

    def clear_audit_log(self) -> None:
        if self._audit:
            self._audit.clear()
