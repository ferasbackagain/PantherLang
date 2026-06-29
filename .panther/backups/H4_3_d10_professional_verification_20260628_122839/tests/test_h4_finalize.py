from io import StringIO

from debug_adapter.dispatcher import RequestDispatcher
from debug_adapter.protocol import encode_message, read_message


def test_end_to_end_debug_adapter():
    dispatcher = RequestDispatcher()

    sequence = [
        {"seq":1,"type":"request","command":"initialize","arguments":{"adapterID":"panther"}},
        {"seq":2,"type":"request","command":"configurationDone"},
        {"seq":3,"type":"request","command":"launch","arguments":{"program":"examples/hello.pan","dryRun":True}},
        {"seq":4,"type":"request","command":"terminate"},
        {"seq":5,"type":"request","command":"disconnect"},
    ]

    for req in sequence:
        framed = encode_message(req)
        parsed = read_message(StringIO(framed))
        assert parsed == req
        resp = dispatcher.dispatch(parsed)
        if req["command"] in ("initialize","configurationDone"):
            assert resp["success"] is True
        elif req["command"]=="launch":
            assert resp["event"]=="process"
            assert resp["body"]["state"]=="running"
        elif req["command"]=="terminate":
            assert resp["event"]=="terminated"
        elif req["command"]=="disconnect":
            assert resp["event"]=="exited"
