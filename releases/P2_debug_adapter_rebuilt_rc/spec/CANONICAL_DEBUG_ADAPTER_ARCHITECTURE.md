# PantherLang Canonical Debug Adapter Architecture

## Purpose

This document defines the clean source-of-truth contract for the rebuilt PantherLang Debug Adapter.

The rebuilt adapter must be independent of historical monkey patches, backup drift, and phase-specific compatibility hacks.

## Core Rule

Never patch a drifting debug adapter architecture. Rebuild from the canonical contract, verify, then replace atomically.

## Required Modules

The rebuilt adapter will live first in:

`debug_adapter_rebuilt/`

and only replace `debug_adapter/` after full regression passes.

Required canonical modules:

- `protocol.py`
- `messages.py`
- `session.py`
- `event_bus.py`
- `event_dispatcher.py`
- `response_dispatcher.py`
- `request_dispatcher.py`
- `execution_dispatcher.py`
- `server.py`
- `launcher.py`
- `breakpoints.py`
- `variables_core.py`
- `variable_references.py`
- `variable_store.py`
- `stack_frames.py`
- `threads.py`
- `scopes.py`
- `evaluate.py`
- `watch_expressions.py`
- `adapter.py`
- `__init__.py`

## Protocol Contract

`encode_message(message)` must return a DAP frame compatible with both:
- bytes-based streams
- legacy StringIO tests

Therefore the canonical protocol must support:
- Content-Length framing
- CRLF separator
- JSON body
- round-trip decode via `read_message`

## Session Contract

`DebugSession` must support:
- initialize
- configurationDone
- launch
- terminate
- disconnect
- state transitions
- callable `capabilities()`
- `apply_initialize_arguments(arguments)`

Capabilities must include:

```json
{
  "supportsConfigurationDoneRequest": true,
  "supportsSetVariable": true,
  "supportsEvaluateForHovers": true,
  "supportsTerminateRequest": true,
  "panther": {
    "realDAPFraming": true,
    "adapter": "pantherlang",
    "protocol": "DAP"
  }
}
```

## Event Contract

EventDispatcher must return real DAP events for:
- launch/process
- continue
- pause
- stop
- terminate
- disconnect

Process event must accept:
- name
- pid
- command
- state
- execution
- request_seq

EventBus must support:
- emit
- publish
- push
- append
- drain
- len(bus)
- iteration

## Request Dispatcher Contract

RequestDispatcher must route:
- initialize -> response
- configurationDone -> response
- setBreakpoints -> response
- launch -> process event
- continue -> continued event
- pause -> stopped event
- stop -> stopped/terminated event
- terminate -> terminated event
- disconnect -> terminated/disconnect response/event compatible with tests

## Debug Data Model Contract

The rebuilt adapter must preserve H4.3 data model:
- variables
- variable references
- variable store
- stack frames
- threads
- scopes
- evaluate
- watch expressions

## Replacement Rule

The old `debug_adapter/` must not be replaced until:
- `debug_adapter_rebuilt/` compiles
- all P2 unit tests pass
- H4 regression passes
- engineering report is generated
- status JSON says replacement is allowed
