from pathlib import Path

from debug_adapter.breakpoint_store import BreakpointStore
from debug_adapter.breakpoints import BreakpointManager
from debug_adapter.validation import BreakpointValidationError, SourceLocationValidator


def test_breakpoint_manager_crud_and_dap_shape(tmp_path):
    source = tmp_path / "main.pan"
    source.write_text("let x = 1\nprint(x)\n", encoding="utf-8")

    manager = BreakpointManager()
    breakpoints = manager.set_breakpoints(str(source), [{"line": 1}, {"line": 2, "condition": "x == 1"}], require_exists=True)

    assert len(breakpoints) == 2
    assert breakpoints[0].verified is True
    assert breakpoints[1].condition == "x == 1"
    assert breakpoints[0].to_dap()["source"]["path"] == str(source)
    assert manager.find_at(str(source), 2)[0].line == 2

    manager.enable_breakpoint(breakpoints[0].id, False)
    assert manager.find_at(str(source), 1) == []

    assert manager.remove_breakpoint(breakpoints[0].id) is True
    assert len(manager.list_breakpoints()) == 1


def test_breakpoint_persistence_round_trip(tmp_path):
    source = tmp_path / "app.pan"
    source.write_text("a\nb\nc\n", encoding="utf-8")
    store = BreakpointStore(str(tmp_path / "breakpoints.json"))

    manager = BreakpointManager()
    manager.set_breakpoints(str(source), [{"line": 3}], require_exists=True)
    manager.save(store)

    restored = BreakpointManager()
    restored.load(store)
    assert restored.list_breakpoints()[0].line == 3
    assert restored.list_breakpoints()[0].source_path == str(source)


def test_validation_rejects_bad_line(tmp_path):
    source = tmp_path / "main.pan"
    source.write_text("only one line\n", encoding="utf-8")
    validator = SourceLocationValidator()
    try:
        validator.validate_location(str(source), 99, require_exists=True)
    except BreakpointValidationError as exc:
        assert "exceeds" in str(exc)
    else:
        raise AssertionError("invalid line was not rejected")
