panther main {
    print("=== PantherLang Network Intelligence ===");
    print("");

    // Host identity
    print("[ Host Identity ]");
    print("Hostname:   " + system_hostname());
    print("Primary IP: " + net_local_ip());
    print("MAC:        " + net_mac_address());
    print("");

    // All local IPs
    print("[ Local IP Addresses ]");
    let ips = net_local_ips();
    for i in 0..len(ips)-1 {
        let ip = ips[i];
        let private = "public";
        if net_is_private_ip(ip) {
            private = "private";
        };
        print("  " + ip + " (" + private + ")");
    };
    print("");

    // Network interfaces
    print("[ Network Interfaces ]");
    let ifs = net_interfaces();
    for i in 0..len(ifs)-1 {
        let mac = net_mac_address(ifs[i]);
        print("  " + ifs[i] + "  MAC: " + mac);
    };
    print("");

    // Gateway and DNS
    print("[ Gateway & DNS ]");
    print("Gateway:    " + net_gateway());
    let dns = net_dns();
    for i in 0..len(dns)-1 {
        print("DNS:        " + dns[i]);
    };
    print("");

    // DNS resolution — deterministic local resolution first.
    // External DNS may be blocked in CI or offline environments.
    print("[ DNS Resolution ]");
    print("localhost:         " + net_resolve("localhost"));
    let local = net_reverse_resolve(net_local_ip());
    if local == "" {
        print("local PTR:         (no reverse record)");
    } else {
        print("local PTR:         " + local);
    };
    print("");

    // ARP neighbors (passive, from local cache)
    print("[ ARP Neighbors (passive) ]");
    let arp = net_scan_lan();
    for i in 0..len(arp)-1 {
        let entry = arp[i];
        print("  " + entry["ip"] + "  " + entry["mac"] + "  [" + entry["interface"] + "]");
    };
    print("");

    // Platform info
    print("[ Platform ]");
    print("OS:          " + system_os());
    print("Arch:        " + system_arch());
    print("CPU Count:   " + to_string(system_cpu_count()));
    print("Uptime:      " + to_string(system_uptime()) + "s");
    print("PID:         " + to_string(system_pid()));
    print("");

    print("=== End ===");
}
