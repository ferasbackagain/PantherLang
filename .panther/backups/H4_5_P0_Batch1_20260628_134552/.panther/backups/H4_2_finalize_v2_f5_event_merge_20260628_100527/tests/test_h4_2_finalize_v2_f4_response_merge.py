from debug_adapter.dispatcher import RequestDispatcher
from debug_adapter.response_dispatcher import ResponseDispatcher
from debug_adapter.response_merge import ResponseMergeEngine


def test_f4_success_response_contract():
    dispatcher = ResponseDispatcher()
    message = dispatcher.success("initialize", request_seq=11, body={"capability": True})

    assert message["type"] == "response"
    assert message["request_seq"] == 11
    assert message["command"] == "initialize"
    assert message["success"] is True
    assert message["body"]["capability"] is True
    assert ResponseMergeEngine().assert_response_contract(message) is True


def test_f4_error_response_contract():
    dispatcher = ResponseDispatcher()
    message = dispatcher.error(
        "launch",
        request_seq=12,
        message="boom",
        body={"code": "E_LAUNCH"},
    )

    assert message["type"] == "response"
    assert message["request_seq"] == 12
    assert message["command"] == "launch"
    assert message["success"] is False
    assert message["message"] == "boom"
    assert message["body"]["code"] == "E_LAUNCH"


def test_f4_normalize_raw_body_into_response():
    dispatcher = ResponseDispatcher()
    message = dispatcher.normalize({"answer": 42}, request_seq=13, command="evaluate")

    assert message["type"] == "response"
    assert message["request_seq"] == 13
    assert message["command"] == "evaluate"
    assert message["success"] is True
    assert message["body"]["answer"] == 42


def test_f4_event_passthrough_keeps_clean_dap_routing():
    dispatcher = ResponseDispatcher()
    event = dispatcher.normalize(
        {"type": "event", "event": "continued", "body": {}},
        request_seq=14,
        command="continue",
    )

    assert event["type"] == "event"
    assert event["event"] == "continued"
    assert event["request_seq"] == 14
    assert event["sourceCommand"] == "continue"


def test_f4_request_dispatcher_uses_merged_response_layer_for_initialize_and_error():
    dispatcher = RequestDispatcher()

    init = dispatcher.dispatch({
        "seq": 21,
        "type": "request",
        "command": "initialize",
        "arguments": {},
    })

    assert init["type"] == "response"
    assert init["request_seq"] == 21
    assert init["command"] == "initialize"
    assert init["success"] is True

    bad = dispatcher.dispatch({
        "seq": 22,
        "type": "request",
        "command": "missingCommand",
    })

    assert bad["type"] == "response"
    assert bad["request_seq"] == 22
    assert bad["command"] == "missingCommand"
    assert bad["success"] is False
    assert "Unsupported command" in bad["message"]
