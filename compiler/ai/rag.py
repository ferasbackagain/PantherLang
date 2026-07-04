from __future__ import annotations

import json
import math
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .providers import AIProvider


@dataclass
class Document:
    text: str
    metadata: dict[str, Any] | None = None
    embedding: list[float] | None = None


class EmbeddingProvider:
    def __init__(self, provider: AIProvider) -> None:
        self._provider = provider

    def embed(self, text: str) -> list[float]:
        return self._provider.embed(text)


class VectorStore:
    def __init__(self) -> None:
        self._documents: list[Document] = []

    def add(self, doc: Document) -> None:
        self._documents.append(doc)

    def search(self, query_embedding: list[float], top_k: int = 5) -> list[tuple[Document, float]]:
        scored: list[tuple[int, float]] = []
        for i, doc in enumerate(self._documents):
            if doc.embedding:
                score = self._cosine_similarity(query_embedding, doc.embedding)
                scored.append((i, score))
        scored.sort(key=lambda x: x[1], reverse=True)
        return [(self._documents[i], score) for i, score in scored[:top_k]]

    @staticmethod
    def _cosine_similarity(a: list[float], b: list[float]) -> float:
        dot = sum(x * y for x, y in zip(a, b))
        norm_a = math.sqrt(sum(x * x for x in a))
        norm_b = math.sqrt(sum(y * y for y in b))
        if norm_a == 0 or norm_b == 0:
            return 0.0
        return dot / (norm_a * norm_b)

    @property
    def count(self) -> int:
        return len(self._documents)

    def save(self, path: str) -> None:
        data = []
        for doc in self._documents:
            data.append({"text": doc.text, "metadata": doc.metadata, "embedding": doc.embedding})
        Path(path).write_text(json.dumps(data, indent=2), encoding="utf-8")

    def load(self, path: str) -> None:
        data = json.loads(Path(path).read_text(encoding="utf-8"))
        self._documents = [Document(text=d["text"], metadata=d.get("metadata"), embedding=d.get("embedding")) for d in data]


class RAGEngine:
    def __init__(self, provider: AIProvider, vector_store: VectorStore | None = None) -> None:
        self._provider = provider
        self._vector_store = vector_store or VectorStore()

    @property
    def store(self) -> VectorStore:
        return self._vector_store

    def query(self, question: str, top_k: int = 3) -> str:
        results = self._vector_store.search(
            self._provider.embed(question),
            top_k=top_k,
        )
        context = "\n\n".join(doc.text for doc, _ in results)
        prompt = f"Context:\n{context}\n\nQuestion: {question}\n\nAnswer based on the context above."
        from .providers import Message
        result = self._provider.complete([Message(role="user", content=prompt)])
        return result.content
