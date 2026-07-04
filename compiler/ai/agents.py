from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Callable

from .providers import AIProvider, CompletionResult, Message


@dataclass
class Tool:
    name: str
    description: str
    fn: Callable[..., str]
    parameters: dict[str, Any] | None = None


@dataclass
class ToolCall:
    tool_name: str
    arguments: dict[str, Any]
    result: str = ""


class Agent:
    def __init__(self, provider: AIProvider, system_prompt: str = "") -> None:
        self._provider = provider
        self._system_prompt = system_prompt
        self._tools: dict[str, Tool] = {}
        self._history: list[Message] = []
        if system_prompt:
            self._history.append(Message(role="system", content=system_prompt))

    def register_tool(self, tool: Tool) -> None:
        self._tools[tool.name] = tool

    def run(self, prompt: str) -> str:
        self._history.append(Message(role="user", content=prompt))
        result = self._provider.complete(self._history)
        content = result.content
        self._history.append(Message(role="assistant", content=content))
        tool_calls = self._parse_tool_calls(content)
        for tc in tool_calls:
            if tc.tool_name in self._tools:
                try:
                    tc.result = self._tools[tc.tool_name].fn(**tc.arguments)
                except Exception as e:
                    tc.result = f"Error: {e}"
                self._history.append(Message(role="tool", content=tc.result))
        if tool_calls:
            follow_up = self._provider.complete(self._history)
            content = follow_up.content
            self._history.append(Message(role="assistant", content=content))
        return content

    def reset(self) -> None:
        self._history.clear()
        if self._system_prompt:
            self._history.append(Message(role="system", content=self._system_prompt))

    @property
    def history(self) -> list[Message]:
        return list(self._history)

    @staticmethod
    def _parse_tool_calls(content: str) -> list[ToolCall]:
        import re
        calls: list[ToolCall] = []
        pattern = r"\{(\w+)\((.*?)\)\}"
        for match in re.finditer(pattern, content):
            name = match.group(1)
            args_str = match.group(2)
            args: dict[str, Any] = {}
            for part in args_str.split(","):
                if "=" in part:
                    k, v = part.split("=", 1)
                    args[k.strip()] = v.strip().strip('"').strip("'")
            calls.append(ToolCall(tool_name=name, arguments=args))
        return calls
