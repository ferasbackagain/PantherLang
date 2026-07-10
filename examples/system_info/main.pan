panther main {
    print("=== PantherLang System Information ===");
    print("Hostname:    " + system_hostname());
    print("OS:          " + system_os());
    print("Arch:        " + system_arch());
    print("Username:    " + system_username());
    print("Home:        " + system_home());
    print("Temp:        " + system_temp());
    print("CWD:         " + system_cwd());
    print("PID:         " + to_string(system_pid()));
    print("PPID:        " + to_string(system_ppid()));
    print("CPU Count:   " + to_string(system_cpu_count()));
    print("Uptime:      " + to_string(system_uptime()) + "s");
    print("Disk:        " + to_string(system_disk(".")));
    print("=== End ===");
}
