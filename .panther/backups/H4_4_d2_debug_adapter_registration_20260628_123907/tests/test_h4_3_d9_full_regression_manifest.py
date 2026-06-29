from pathlib import Path


def test_d9_h4_3_required_modules_exist():
    required = [
        "debug_adapter/variables_core.py",
        "debug_adapter/variable_references.py",
        "debug_adapter/variable_store.py",
        "debug_adapter/stack_frames.py",
        "debug_adapter/threads.py",
        "debug_adapter/scopes.py",
        "debug_adapter/evaluate.py",
        "debug_adapter/watch_expressions.py",
        "debug_adapter/variables.py",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing H4.3 module: {item}"


def test_d9_h4_3_status_files_exist():
    required = [
        ".panther/phase_status/H4_3_d1_variables_core.json",
        ".panther/phase_status/H4_3_d2_variables_references.json",
        ".panther/phase_status/H4_3_d3_variable_store.json",
        ".panther/phase_status/H4_3_d4_stack_frames.json",
        ".panther/phase_status/H4_3_d5_threads.json",
        ".panther/phase_status/H4_3_d6_scopes.json",
        ".panther/phase_status/H4_3_d7_evaluate.json",
        ".panther/phase_status/H4_3_d8_watch_expressions.json",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing H4.3 status file: {item}"


def test_d9_h4_3_reports_exist():
    required = [
        "docs/hardening/H4_3_D1_VARIABLES_CORE_REPORT.md",
        "docs/hardening/H4_3_D2_VARIABLES_REFERENCES_REPORT.md",
        "docs/hardening/H4_3_D3_VARIABLE_STORE_REPORT.md",
        "docs/hardening/H4_3_D4_STACK_FRAMES_REPORT.md",
        "docs/hardening/H4_3_D5_THREADS_REPORT.md",
        "docs/hardening/H4_3_D6_SCOPES_REPORT.md",
        "docs/hardening/H4_3_D7_EVALUATE_REPORT.md",
        "docs/hardening/H4_3_D8_WATCH_EXPRESSIONS_REPORT.md",
    ]

    for item in required:
        assert Path(item).exists(), f"Missing H4.3 report: {item}"
