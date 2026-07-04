from cli.panther_cli import main, _print_help, _version, _doctor


def test_cli_no_args_returns_zero():
    code = main([])
    assert code == 0


def test_cli_help():
    code = main(["help"])
    assert code == 0


def test_cli_help_flag():
    code = main(["--help"])
    assert code == 0


def test_cli_help_short():
    code = main(["-h"])
    assert code == 0


def test_cli_version():
    code = main(["version"])
    assert code == 0


def test_cli_version_flag():
    code = main(["--version"])
    assert code == 0


def test_cli_version_short():
    code = main(["-v"])
    assert code == 0


def test_cli_doctor():
    code = main(["doctor"])
    assert code == 0


def test_print_help_contains_panther():
    out = _capture_print_help()
    assert "PantherLang" in out or "Panther" in out
    assert "run" in out
    assert "doctor" in out
    assert "version" in out


def test_print_help_contains_resources():
    out = _capture_print_help()
    assert "GitHub" in out or "github" in out
    assert "QUICK START" in out


def test_print_help_professional():
    out = _capture_print_help()
    assert "Modern" in out
    assert "Secure" in out
    assert "AI-Native" in out
    assert "Cross-Platform" in out
    assert "Programming Language" in out


def test_print_help_commands():
    out = _capture_print_help()
    assert "run --serve" in out
    assert "build" in out
    assert "check" in out
    assert "fmt" in out
    assert "new" in out
    assert "help" in out


def test_print_help_examples():
    out = _capture_print_help()
    assert "console_hello" in out
    assert "calculator" in out


def test_print_help_resources():
    out = _capture_print_help()
    assert "github.com" in out or "GitHub" in out
    assert "Docs" in out


def test_version_contains_version():
    out = _capture_version()
    assert "1.0.0" in out or "PantherLang" in out


def test_doctor_contains_ok():
    out = _capture_doctor()
    assert "PantherLang" in out


def test_doctor_all_components_ok():
    out = _capture_doctor()
    components = ["compiler", "runtime", "stdlib", "types", "web", "database", "AI", "security", "package mgr", "templates"]
    for comp in components:
        assert comp in out, f"Doctor output missing component: {comp}"
    assert "OK" in out
    assert "PantherLang is ready" in out or "PantherLang is ready" in out


def test_cli_unknown_command():
    code = main(["nonexistent"])
    assert code == 2


def test_cli_run_without_args():
    code = main(["run"])
    assert code == 2


def test_cli_check_without_args():
    code = main(["check"])
    assert code == 2


def test_cli_fmt_without_args():
    code = main(["fmt"])
    assert code == 2


def test_cli_new_without_args():
    code = main(["new"])
    assert code == 2


def test_cli_build_without_args():
    code = main(["build"])
    assert code == 2


# Helpers that capture stdout

def _capture_print_help():
    import io, sys
    captured = io.StringIO()
    old_stdout = sys.stdout
    sys.stdout = captured
    try:
        _print_help()
    finally:
        sys.stdout = old_stdout
    return captured.getvalue()


def _capture_version():
    import io, sys
    captured = io.StringIO()
    old_stdout = sys.stdout
    sys.stdout = captured
    try:
        _version()
    finally:
        sys.stdout = old_stdout
    return captured.getvalue()


def _capture_doctor():
    import io, sys
    captured = io.StringIO()
    old_stdout = sys.stdout
    sys.stdout = captured
    try:
        _doctor()
    finally:
        sys.stdout = old_stdout
    return captured.getvalue()
