panther main {
    print "=== Lab 16: Contributing & Ecosystem Solutions ===";
    print "";

    print "Exercise 1: Development environment setup";
    print "";
    let os_type = system_os();
    let python_ver = system_env("PYTHON_VERSION", "3.10+");
    print "  Current environment:";
    print "    OS: " + os_type;
    print "    Host: " + system_hostname();
    print "    User: " + system_username();
    print "    Python: " + python_ver;
    print "    CWD: " + system_cwd();
    print "    CPU cores: " + string(system_cpu_count());
    print "";
    print "  Setup steps:";
    print "    git clone https://github.com/pantherlang/pantherlang.git";
    print "    cd pantherlang";
    print "    pip install -e \".[dev]\"";
    print "";

    print "Exercise 2: Running tests";
    print "";
    print "  Commands:";
    print "    python -m pytest tests/security/test_web_security.py -v";
    print "    python -m pytest tests/test_array_dict_support.py -v";
    print "    python -m pytest tests/test_stdlib_phase6.py -v";
    print "";

    print "Exercise 3: Creating a project from a template";
    print "";
    print "  Available templates: console, web, api, ai";
    print "  Example (console template):";
    print "    mkdir my_console_app";
    print "    cd my_console_app";
    print "    # Copy from project_templates/console/";
    print "    python -m cli.panther_cli run main.pan";
    print "";

    print "=== Lab 16 Complete ===";
}
