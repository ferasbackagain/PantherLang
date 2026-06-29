from debug_adapter.dispatcher import RequestDispatcher


REQUIRED_COMMANDS = [
    "initialize",
    "configurationDone",
    "setBreakpoints",
    "launch",
    "continue",
    "pause",
    "stop",
    "terminate",
    "disconnect",
]


def get_dispatcher_commands():
    dispatcher = RequestDispatcher()
    routes = getattr(dispatcher, "routes", {})
    return sorted(routes.keys())


def validate_dispatcher_contract():
    commands = set(get_dispatcher_commands())
    missing = [cmd for cmd in REQUIRED_COMMANDS if cmd not in commands]
    if missing:
        raise RuntimeError("dispatcher missing required commands: " + ", ".join(missing))
    return True


def dispatch_smoke_sequence():
    dispatcher = RequestDispatcher()
    results = []

    sequence = [
        {"seq": 1, "type": "request", "command": "initialize", "arguments": {"adapterID": "panther"}},
        {"seq": 2, "type": "request", "command": "configurationDone"},
        {
            "seq": 3,
            "type": "request",
            "command": "setBreakpoints",
            "arguments": {
                "source": {"path": "examples/hello.pan"},
                "breakpoints": [{"line": 1}],
            },
        },
        {
            "seq": 4,
            "type": "request",
            "command": "launch",
            "arguments": {"program": "examples/hello.pan", "dryRun": True},
        },
        {"seq": 5, "type": "request", "command": "continue", "arguments": {"threadId": 1}},
        {"seq": 6, "type": "request", "command": "pause", "arguments": {"threadId": 1}},
        {"seq": 7, "type": "request", "command": "stop", "arguments": {"threadId": 1}},
        {"seq": 8, "type": "request", "command": "terminate"},
        {"seq": 9, "type": "request", "command": "disconnect"},
    ]

    for request in sequence:
        results.append(dispatcher.dispatch(request))

    return results
