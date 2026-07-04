from __future__ import annotations

import re
import time
from dataclasses import dataclass, field
from typing import Any


_PROMPT_INJECTION_PATTERNS: list[re.Pattern] = [
    re.compile(r"(?i)ignore\s+(all\s+)?(previous|above|below)\s+instructions"),
    re.compile(r"(?i)forget\s+(all\s+)?(previous|prior|above)"),
    re.compile(r"(?i)system\s+prompt"),
    re.compile(r"(?i)you\s+are\s+(now|not)\s+(an?\s+)?(AI|assistant|chatbot|GPT|model)"),
    re.compile(r"(?i)do\s+not\s+(follow|obey|listen)"),
    re.compile(r"(?i)override\s+(your\s+)?(instructions|directives|guidelines)"),
    re.compile(r"(?i)act\s+as\s+(if|though)\s+you\s+are"),
    re.compile(r"(?i)from\s+now\s+on\s+you\s+are"),
    re.compile(r"(?i)pretend\s+to\s+be"),
    re.compile(r"(?i)Ignore all (prior|previous|above)"),

    re.compile(r"<[^>]*>.*?</[^>]*>"),
    re.compile(r"(?i)(begin|end)\s+(system|user|assistant|tool)\s+(instruction|message|prompt)"),
]


@dataclass
class PromptInjectionResult:
    detected: bool = False
    score: float = 0.0
    matched_patterns: list[str] = field(default_factory=list)

    def __bool__(self) -> bool:
        return self.detected


class PromptInjectionDetector:
    @staticmethod
    def analyze(text: str) -> PromptInjectionResult:
        result = PromptInjectionResult()
        for pattern in _PROMPT_INJECTION_PATTERNS:
            if pattern.search(text):
                result.detected = True
                result.score += 0.15
                result.matched_patterns.append(pattern.pattern)
        result.score = min(result.score, 1.0)
        return result


@dataclass
class AuditEntry:
    timestamp: float = 0.0
    agent_id: str = ""
    tool_name: str = ""
    arguments: dict[str, Any] = field(default_factory=dict)
    result: str = ""
    prompt: str = ""


class ToolCallAudit:
    def __init__(self) -> None:
        self._log: list[AuditEntry] = []

    def record(self, entry: AuditEntry) -> None:
        self._log.append(entry)

    def get_log(self) -> list[AuditEntry]:
        return list(self._log)

    def clear(self) -> None:
        self._log.clear()

    def to_dict(self) -> list[dict[str, Any]]:
        return [
            {
                "timestamp": e.timestamp,
                "agent_id": e.agent_id,
                "tool_name": e.tool_name,
                "arguments": e.arguments,
                "result_preview": e.result[:100] if e.result else "",
            }
            for e in self._log
        ]


class OutputValidator:
    @staticmethod
    def contains_sensitive_data(text: str) -> bool:
        patterns = [
            r"\b\d{16,19}\b",
            r"\b(?:sk|pk)[-_][a-zA-Z0-9]{20,}\b",
            r"\b[A-Za-z0-9+/]{40,}={0,2}\b",
        ]
        for p in patterns:
            if re.search(p, text):
                return True
        return False

    @staticmethod
    def sanitize_output(text: str) -> str:
        patterns = [
            (r"\b\d{16,19}\b", "[REDACTED]"),
            (r"\b(?:sk|pk)[-_][a-zA-Z0-9]{20,}\b", "[REDACTED]"),
        ]
        for pattern, replacement in patterns:
            text = re.sub(pattern, replacement, text)
        return text
