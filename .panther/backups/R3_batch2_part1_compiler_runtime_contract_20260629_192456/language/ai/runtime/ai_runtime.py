#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


class PantherAIRuntimeError(Exception):
    pass


class DeterministicMockProvider:
    """Local provider for Phase 5.1.

    It intentionally does not call external APIs. This gives PantherLang a
    stable testable AI runtime boundary before real providers are integrated.
    """

    def run(self, contract: dict[str, Any]) -> dict[str, Any]:
        required = ["id", "capability", "input", "policy"]
        missing = [key for key in required if key not in contract]
        if missing:
            raise PantherAIRuntimeError(f"Missing prompt contract keys: {', '.join(missing)}")

        text = str(contract["input"]).strip()
        capability = str(contract["capability"])

        if capability == "ai.text.classify":
            result = "non_empty" if text else "empty"
        elif capability == "ai.code.explain":
            result = "Phase 5.1 mock explanation: source received and bounded by policy."
        else:
            fallback = contract.get("deterministic_fallback")
            result = fallback or f"Phase 5.1 mock response for: {text[:80]}"

        return {
            "provider": "deterministic_mock",
            "phase": "5.1",
            "contract_id": contract["id"],
            "capability": capability,
            "policy": contract["policy"],
            "result": result,
            "external_api_used": False
        }


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise PantherAIRuntimeError(f"Invalid JSON in {path}: {exc}") from exc


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="panther-ai-runtime")
    parser.add_argument("contract", help="Path to prompt contract JSON")
    parser.add_argument("--pretty", action="store_true", help="Pretty-print JSON output")
    args = parser.parse_args(argv)

    contract_path = Path(args.contract)
    if not contract_path.exists():
        raise SystemExit(f"Prompt contract not found: {contract_path}")

    contract = load_json(contract_path)
    output = DeterministicMockProvider().run(contract)

    if args.pretty:
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        print(json.dumps(output, ensure_ascii=False))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
