panther main {
    // Process execution
    fn panther_process_run(command, args, env, timeout, cwd) {
        // Not implemented - requires shell execution
        return {ok: false, error: "process execution not supported"};
    }

    fn panther_process_spawn(command, args, env, cwd) {
        // Not implemented - requires background process
        return {ok: false, error: "process spawning not supported"};
    }

    fn panther_process_kill(pid, signal) {
        // Not implemented
        return false;
    }

    fn panther_process_wait(pid, timeout) {
        // Not implemented
        return {ok: false, error: "process wait not supported"};
    }

    // Current process info
    fn panther_process_self_pid() {
        return system_pid();
    }

    fn panther_process_self_ppid() {
        return system_ppid();
    }

    fn panther_process_self_env() {
        // Not implemented - return empty object
        return {};
    }

    fn panther_process_self_cwd() {
        return system_cwd();
    }

    fn panther_process_self_argv() {
        let args = [];
        // Not directly accessible
        return args;
    }

    fn panther_process_self_exe() {
        // Not implemented
        return "";
    }
}