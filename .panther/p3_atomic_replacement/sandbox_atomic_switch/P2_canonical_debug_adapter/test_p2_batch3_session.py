from debug_adapter_rebuilt.session import DebugSession

def test_session_contract():
    s=DebugSession()
    s.apply_initialize_arguments({"adapterID":"panther"})
    assert s.initialized
    assert s.state=="initialized"
    assert s.capabilities()["panther"]["realDAPFraming"]
    s.configuration_done()
    assert s.state=="configured"
    info=s.launch("main.pan")
    assert info["program"]=="main.pan"
    assert s.state=="running"
    s.terminate()
    assert s.state=="terminated"
    s.disconnect()
    assert s.state=="disconnected"
