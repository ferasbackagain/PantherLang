from pathlib import Path


class FinalizeV2ArchitectureError(RuntimeError):
    pass


REQUIRED_MODULES = [
    "dispatcher.py",
    "server.py",
    "protocol.py",
    "execution_controller.py",
    "execution_state.py",
    "event_dispatcher.py",
    "response_dispatcher.py",
    "event_bus.py",
    "events.py",
]


def validate_debug_adapter_architecture(root="debug_adapter"):
    base = Path(root)
    missing = [name for name in REQUIRED_MODULES if not (base / name).exists()]
    if missing:
        raise FinalizeV2ArchitectureError(
            "missing debug adapter modules: " + ", ".join(missing)
        )
    return {
        "root": str(base),
        "required": list(REQUIRED_MODULES),
        "missing": [],
        "status": "ok",
    }


def validate_no_known_broken_part2b_signature(root="debug_adapter"):
    dispatcher = Path(root) / "dispatcher.py"
    if not dispatcher.exists():
        raise FinalizeV2ArchitectureError("dispatcher.py is missing")

    text = dispatcher.read_text()
    broken_signatures = [
        'response.get("success") is not False',
        'Unsupported command: continue',
        'Unsupported command: pause',
        'Unsupported command: stop',
    ]
    found = [sig for sig in broken_signatures if sig in text]
    if found:
        raise FinalizeV2ArchitectureError(
            "legacy/broken Part2B signatures detected: " + ", ".join(found)
        )
    return True
