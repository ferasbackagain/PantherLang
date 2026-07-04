from __future__ import annotations

import json
import os
from dataclasses import dataclass
from typing import Any


@dataclass
class Message:
    role: str = "user"
    content: str = ""


@dataclass
class CompletionResult:
    content: str = ""
    model: str = ""
    usage: dict[str, int] | None = None


class AIProvider:
    def complete(self, messages: list[Message], **kwargs: Any) -> CompletionResult:
        raise NotImplementedError

    def embed(self, text: str) -> list[float]:
        raise NotImplementedError

    @property
    def name(self) -> str:
        return self.__class__.__name__


class OpenAIProvider(AIProvider):
    def __init__(self, api_key: str | None = None, model: str = "gpt-4o") -> None:
        self.api_key = api_key if api_key is not None else os.environ.get("OPENAI_API_KEY", "")
        self.model = model

    def complete(self, messages: list[Message], **kwargs: Any) -> CompletionResult:
        if not self.api_key:
            return CompletionResult(content="[mock] OpenAI response: " + messages[-1].content if messages else "", model=self.model)
        try:
            import openai
            client = openai.OpenAI(api_key=self.api_key)
            response = client.chat.completions.create(
                model=self.model,
                messages=[{"role": m.role, "content": m.content} for m in messages],
                **kwargs,
            )
            return CompletionResult(
                content=response.choices[0].message.content or "",
                model=self.model,
                usage=dict(response.usage) if response.usage else None,
            )
        except (ImportError, Exception):
            return CompletionResult(content="[mock] OpenAI response: " + messages[-1].content if messages else "", model=self.model)

    def embed(self, text: str) -> list[float]:
        if not self.api_key:
            return [hash(text) % 1000 / 1000.0]
        try:
            import openai
            client = openai.OpenAI(api_key=self.api_key)
            resp = client.embeddings.create(input=text, model="text-embedding-3-small")
            return resp.data[0].embedding
        except (ImportError, Exception):
            return [hash(text) % 1000 / 1000.0]


class AnthropicProvider(AIProvider):
    def __init__(self, api_key: str | None = None, model: str = "claude-sonnet-4-20250514") -> None:
        self.api_key = api_key if api_key is not None else os.environ.get("ANTHROPIC_API_KEY", "")
        self.model = model

    def complete(self, messages: list[Message], **kwargs: Any) -> CompletionResult:
        if not self.api_key:
            return CompletionResult(content="[mock] Anthropic response: " + messages[-1].content if messages else "", model=self.model)
        try:
            import anthropic
            client = anthropic.Anthropic(api_key=self.api_key)
            response = client.messages.create(
                model=self.model,
                messages=[{"role": m.role, "content": m.content} for m in messages],
                **kwargs,
            )
            return CompletionResult(
                content=response.content[0].text if response.content else "",
                model=self.model,
            )
        except ImportError:
            return CompletionResult(content="[mock] Anthropic response: " + messages[-1].content if messages else "", model=self.model)


class GeminiProvider(AIProvider):
    def __init__(self, api_key: str | None = None, model: str = "gemini-2.0-flash") -> None:
        self.api_key = api_key if api_key is not None else os.environ.get("GEMINI_API_KEY", "")
        self.model = model

    def complete(self, messages: list[Message], **kwargs: Any) -> CompletionResult:
        if not self.api_key:
            return CompletionResult(content="[mock] Gemini response: " + messages[-1].content if messages else "", model=self.model)
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.api_key)
            model = genai.GenerativeModel(self.model)
            response = model.generate_content(messages[-1].content if messages else "")
            return CompletionResult(content=response.text, model=self.model)
        except (ImportError, Exception):
            return CompletionResult(content="[mock] Gemini response: " + messages[-1].content if messages else "", model=self.model)


class OllamaProvider(AIProvider):
    def __init__(self, base_url: str = "http://localhost:11434", model: str = "llama3") -> None:
        self.base_url = base_url
        self.model = model

    def complete(self, messages: list[Message], **kwargs: Any) -> CompletionResult:
        try:
            import requests
            payload = {
                "model": self.model,
                "messages": [{"role": m.role, "content": m.content} for m in messages],
                "stream": False,
            }
            resp = requests.post(f"{self.base_url}/api/chat", json=payload, timeout=5)
            data = resp.json()
            return CompletionResult(content=data.get("message", {}).get("content", ""), model=self.model)
        except (ImportError, requests.exceptions.ConnectionError, Exception):
            return CompletionResult(content="[mock] Ollama response: " + messages[-1].content if messages else "", model=self.model)


class OpenRouterProvider(AIProvider):
    def __init__(self, api_key: str | None = None, model: str = "openai/gpt-4o") -> None:
        self.api_key = api_key if api_key is not None else os.environ.get("OPENROUTER_API_KEY", "")
        self.model = model

    def complete(self, messages: list[Message], **kwargs: Any) -> CompletionResult:
        if not self.api_key:
            return CompletionResult(content="[mock] OpenRouter response: " + messages[-1].content if messages else "", model=self.model)
        try:
            import requests
            resp = requests.post(
                "https://openrouter.ai/api/v1/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={"model": self.model, "messages": [{"role": m.role, "content": m.content} for m in messages]},
                timeout=30,
            )
            data = resp.json()
            return CompletionResult(
                content=data["choices"][0]["message"]["content"],
                model=self.model,
            )
        except (ImportError, Exception):
            return CompletionResult(content="[mock] OpenRouter response: " + messages[-1].content if messages else "", model=self.model)
