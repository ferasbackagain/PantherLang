panther main {
    // System info
    fn panther_system_hostname() {
        return system_hostname();
    }

    fn panther_system_os() {
        return system_os();
    }

    fn panther_system_arch() {
        return system_arch();
    }

    fn panther_system_username() {
        return system_username();
    }

    fn panther_system_env(name, default) {
        return system_env(name, default);
    }

    fn panther_system_cpu_count() {
        return system_cpu_count();
    }

    fn panther_system_memory() {
        return system_memory();
    }

    fn panther_system_disk(path) {
        return system_disk(path);
    }

    fn panther_system_uptime() {
        return system_uptime();
    }

    fn panther_system_cwd() {
        return system_cwd();
    }

    fn panther_system_pid() {
        return system_pid();
    }

    fn panther_system_ppid() {
        return system_ppid();
    }

    fn panther_system_command_line() {
        return system_command_line();
    }

    fn panther_system_home() {
        return system_home();
    }

    fn panther_system_temp() {
        return system_temp();
    }

    fn panther_system_exit(code) {
        system_exit(code);
    }
}