# H4.1 Part 1 — Debug Adapter Core

This milestone introduces the first real PantherLang Debug Adapter Protocol subsystem.

Implemented package:

```text
debug_adapter/
  __init__.py
  adapter.py
  launcher.py
  messages.py
  protocol.py
  server.py
  session.py
  transport.py
```

Implemented CLI:

```bash
./panther dap start
./panther dap doctor
./panther dap version
```

Verification performs real DAP framing with `Content-Length` headers and the handshake:

```text
client -> initialize -> adapter response
adapter -> initialized event
client -> disconnect -> adapter response
adapter -> terminated/exited events
```

H4.1 Part 1 intentionally does not claim breakpoints, stack frames, variables, or VS Code debugger registration. Those belong to H4.2, H4.3, and H4.4.
