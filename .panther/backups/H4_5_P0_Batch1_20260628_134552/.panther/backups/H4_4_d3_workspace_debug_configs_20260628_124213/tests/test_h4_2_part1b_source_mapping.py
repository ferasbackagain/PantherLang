from debug_adapter.breakpoints import BreakpointManager
from debug_adapter.source_map import PantherSourceMap


def test_source_map_registers_executable_lines(tmp_path):
    source = tmp_path / "main.pan"
    source.write_text("// comment\n\nlet x = 1\nprint(x)\n", encoding="utf-8")

    source_map = PantherSourceMap()
    info = source_map.register_file(str(source), require_exists=True)

    assert info.line_count == 4
    assert info.executable_lines == {3, 4}


def test_source_map_moves_non_executable_line_to_next_executable(tmp_path):
    source = tmp_path / "main.pan"
    source.write_text("// comment\n\nlet x = 1\n", encoding="utf-8")
    source_map = PantherSourceMap()
    source_map.register_file(str(source), require_exists=True)

    resolved_line, verified, message = source_map.resolve_breakpoint_line(str(source), 1)
    assert resolved_line == 3
    assert verified is True
    assert "moved breakpoint" in message


def test_breakpoint_manager_and_source_map_integration_shape(tmp_path):
    source = tmp_path / "program.pan"
    source.write_text("\nlet alpha = 1\n", encoding="utf-8")
    source_map = PantherSourceMap()
    source_map.register_file(str(source), require_exists=True)
    resolved, verified, message = source_map.resolve_breakpoint_line(str(source), 1)

    manager = BreakpointManager()
    breakpoints = manager.set_breakpoints(str(source), [{"line": resolved}], require_exists=True)

    assert verified is True
    assert breakpoints[0].line == 2
