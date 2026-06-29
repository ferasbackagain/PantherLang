from debug_adapter_rebuilt.server import DebugServer

def test_server_flow():
    s=DebugServer()
    assert s.dispatch({"seq":1,"command":"initialize","arguments":{"adapterID":"panther"}})["success"]
    assert s.dispatch({"seq":2,"command":"configurationDone"})["success"]
    launch=s.dispatch({"seq":3,"command":"launch","arguments":{"program":"hello.pan"}})
    assert launch["type"]=="event"
    assert launch["event"]=="process"
    assert launch["body"]["name"]=="hello.pan"
    assert s.dispatch({"seq":4,"command":"continue"})["event"]=="continued"
    assert s.dispatch({"seq":5,"command":"terminate"})["event"]=="terminated"
