from __future__ import annotations

from dataclasses import dataclass


@dataclass
class TokenCursor:
    """Mutable cursor used by TokenStream for deterministic parser navigation."""

    position: int = 0

    def save(self) -> int:
        return self.position

    def restore(self, checkpoint: int) -> None:
        if checkpoint < 0:
            raise ValueError("TokenCursor checkpoint cannot be negative")
        self.position = checkpoint

    def advance(self, amount: int = 1) -> int:
        if amount < 0:
            raise ValueError("TokenCursor cannot advance by a negative amount")
        self.position += amount
        return self.position

    def rewind(self, amount: int = 1) -> int:
        if amount < 0:
            raise ValueError("TokenCursor cannot rewind by a negative amount")
        self.position = max(0, self.position - amount)
        return self.position
