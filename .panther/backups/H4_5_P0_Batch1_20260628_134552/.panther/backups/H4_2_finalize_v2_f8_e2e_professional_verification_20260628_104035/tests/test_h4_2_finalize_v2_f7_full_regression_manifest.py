from pathlib import Path


def test_f7_h4_2_core_modules_exist():
    required = [
        "debug_adapter/dispatcher.py",
        "debug_adapter/response_dispatcher.py",
        "debug_adapter/response_merge.py",
        "debug_adapter/event_dispatcher.py",
        "debug_adapter/event_merge.py",
        "debug_adapter/execution_dispatcher.py",
        "debug_adapter/execution_merge.py",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing required H4.2 module: {item}"


def test_f7_h4_2_phase_status_files_exist():
    required = [
        ".panther/phase_status/H4_2_finalize_v2_f4_response_merge.json",
        ".panther/phase_status/H4_2_f5_event_request_seq_patch.json",
        ".panther/phase_status/H4_2_finalize_v2_f6_execution_merge.json",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing required H4.2 status file: {item}"


def test_f7_h4_2_reports_exist():
    required = [
        "docs/hardening/H4_2_FINALIZE_V2_F4_RESPONSE_MERGE_REPORT.md",
        "docs/hardening/H4_2_F5_EVENT_REQUEST_SEQ_COMPATIBILITY_REPORT.md",
        "docs/hardening/H4_2_FINALIZE_V2_F6_EXECUTION_MERGE_REPORT.md",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing required H4.2 report: {item}"
