# Panther Recovery Engine - P-1 Batch 4 v3

## Status

NEEDS_RECONSTRUCTION

## Purpose

Safely test immutable debug_adapter candidate snapshots without deleting the live candidate source.

## Best Candidate

```json
{
  "source_path": ".panther/backups/H4_3_d10_professional_verification_20260628_123054/debug_adapter",
  "snapshot_path": "/tmp/panther_recovery_candidates_20260629_090934/candidates/_panther__backups__H4_3_d10_professional_verification_20260628_123054__debug_adapter",
  "rank": 4,
  "compile_rc": 0,
  "pytest_rc": 1,
  "failed_count": 3,
  "error_count": 0,
  "missing_required": [],
  "stdout_tail": "FF..............................................F....................... [ 41%]\n........................................................................ [ 83%]\n............................                                             [100%]\n=================================== FAILURES ===================================\n_________________________ test_dap_protocol_roundtrip __________________________\n\n    def test_dap_protocol_roundtrip():\n        msg = {\"seq\": 1, \"type\": \"request\", \"command\": \"initialize\", \"arguments\": {\"adapterID\": \"pantherlang\"}}\n>       stream = io.BytesIO(encode_message(msg))\n                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\nE       TypeError: a bytes-like object is required, not 'str'\n\ntests/H4_1/test_debug_adapter_core.py:11: TypeError\n___________________ test_session_capabilities_are_dap_ready ____________________\n\n    def test_session_capabilities_are_dap_ready():\n        s = DebugSession()\n>       s.apply_initialize_arguments({\"clientID\": \"pytest\", \"adapterID\": \"pantherlang\"})\n        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^\nE       AttributeError: 'DebugSession' object has no attribute 'apply_initialize_arguments'\n\ntests/H4_1/test_debug_adapter_core.py:17: AttributeError\n_____________ test_event_dispatcher_emits_and_queues_process_event _____________\n\n    def test_event_dispatcher_emits_and_queues_process_event():\n        bus = EventBus()\n        dispatcher = EventDispatcher(bus)\n        event = dispatcher.process(\n            name=\"main.pan\",\n            command=[\"Panther\", \"run\", \"main.pan\"],\n            state=\"running\",\n            execution={\"status\": \"ready\"},\n            request_seq=7,\n        )\n        assert event[\"type\"] == \"event\"\n        assert event[\"event\"] == \"process\"\n>       assert event[\"request_seq\"] == 7\n               ^^^^^^^^^^^^^^^^^^^^\nE       KeyError: 'request_seq'\n\ntests/test_h4_2_part2b_v2_core.py:18: KeyError\n=========================== short test summary info ============================\nFAILED tests/H4_1/test_debug_adapter_core.py::test_dap_protocol_roundtrip - T...\nFAILED tests/H4_1/test_debug_adapter_core.py::test_session_capabilities_are_dap_ready\nFAILED tests/test_h4_2_part2b_v2_core.py::test_event_dispatcher_emits_and_queues_process_event\n3 failed, 169 passed in 1.85s\n",
  "stderr_tail": ""
}
```

## Tested Candidates

60