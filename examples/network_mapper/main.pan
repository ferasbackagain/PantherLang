panther main {
    // ============================================================
    // PantherLang Network Intelligence Engine — Network Mapper
    // ============================================================
    let scan_start = time_now();

    // --- Configuration ---
    let target = "127.0.0.1";
    let ports = [22, 80, 443, 8080];
    let connect_timeout_ms = 500;
    let banner_timeout_ms = 500;

    // ============================================================
    // SECTION: Local System Identity
    // ============================================================
    print("============================================================");
    print(" PantherLang Network Intelligence Engine");
    print("============================================================");
    print("");
    print("Local Host");
    let hostname = system_hostname();
    let platform_os = system_os();
    let primary = net_primary_ip();
    let gateway = net_gateway();
    print("  Hostname       : " + hostname);
    print("  Platform       : " + platform_os);
    print("  Primary IP     : " + primary);
    print("  Gateway        : " + gateway);
    print("");

    // ============================================================
    // SECTION: Interfaces
    // ============================================================
    print("Interfaces");
    let ifs = net_interfaces();
    let if_count = len(ifs);
    if if_count > 0 {
        for i in 0..(if_count - 1) {
            let name = ifs[i];
            let mac = net_mac_address(name);
            print("  " + name);
            if mac != "" {
                print("    MAC         : " + mac);
            }
        }
    } else {
        print("  (none)");
    }
    print("");

    // ============================================================
    // SECTION: DNS Servers
    // ============================================================
    print("DNS Servers");
    let dns_servers = net_dns();
    let dns_count = len(dns_servers);
    if dns_count > 0 {
        for i in 0..(dns_count - 1) {
            print("  " + dns_servers[i]);
        }
    } else {
        print("  (none detected)");
    }
    print("");

    // ============================================================
    // SECTION: Passive Neighbors (ARP cache)
    // ============================================================
    print("Passive Neighbors");
    let neighbors = net_scan_lan();
    let neighbor_count = len(neighbors);
    if neighbor_count > 0 {
        for i in 0..(neighbor_count - 1) {
            let entry = neighbors[i];
            let ip_str = entry["ip"];
            let mac_str = entry["mac"];
            let if_str = entry["interface"];
            print("  " + ip_str + "  MAC: " + mac_str + "  [" + if_str + "]");
        }
    } else {
        print("  (none detected)");
    }
    print("");

    // ============================================================
    // SECTION: DNS Resolution
    // ============================================================
    print("DNS Correlation");
    print("  Target        : " + target);
    let target_reverse = net_reverse_resolve(target);
    if target_reverse != "" {
        print("  Reverse DNS   : " + target_reverse);
    } else {
        print("  Reverse DNS   : (no PTR record)");
    }
    print("");

    // ============================================================
    // SECTION: Port Scan
    // ============================================================
    let scan_start_time = time_now();
    let port_count = len(ports);
    print("Port Scan");
    print("  Target        : " + target);
    print("  Ports         : " + to_string(port_count));
    print("  Timeout       : " + to_string(connect_timeout_ms) + " ms");
    print("");

    let open_results = [];
    let closed_count = 0;
    let timeout_count = 0;
    let error_count = 0;

    for i in 0..(port_count - 1) {
        let port_num = ports[i];
        let connect_start = time_now();
        let state = tcp_connect(target, port_num, connect_timeout_ms);
        let elapsed_ms = to_int((time_now() - connect_start) * 1000);

        if state == "open" {
            // Collect banner on open ports
            let banner = tcp_banner(target, port_num, banner_timeout_ms);
            let svc_info = net_infer_service(port_num, banner, target_reverse);

            let entry = {
                port: port_num,
                state: state,
                latency_ms: elapsed_ms,
                service: svc_info.service,
                confidence: svc_info.confidence,
                evidence: svc_info.evidence,
                banner: banner
            };
            array_push(open_results, entry);
        } else {
            if state == "timeout" {
                timeout_count = timeout_count + 1;
            } else {
                if state == "connection_refused" {
                    closed_count = closed_count + 1;
                } else {
                    error_count = error_count + 1;
                }
            }
        }
    }

    let scan_duration = time_now() - scan_start_time;

    // ============================================================
    // SECTION: Results
    // ============================================================
    let open_count = len(open_results);
    print("Observed Services");
    if open_count > 0 {
        for j in 0..(open_count - 1) {
            let r = open_results[j];
            print("  " + to_string(r.port) + "/tcp");
            print("    State       : " + r.state);
            print("    Latency     : " + to_string(r.latency_ms) + " ms");
            print("    Service     : " + r.service);
            print("    Confidence  : " + r.confidence);
            print("    Evidence    : " + r.evidence);
            if r.banner != "" {
                print("    Banner      : " + r.banner);
            }
        }
    } else {
        print("  (no open ports found)");
    }
    print("");

    // ============================================================
    // SECTION: Summary
    // ============================================================
    let total_duration = time_now() - scan_start;
    let total_sec = to_int(total_duration);
    print("Summary");
    print("  Hosts tested  : 1");
    print("  Ports scanned : " + to_string(port_count));
    print("  Open ports    : " + to_string(open_count));
    print("  Closed ports  : " + to_string(closed_count));
    print("  Timeouts      : " + to_string(timeout_count));
    print("  Errors        : " + to_string(error_count));
    print("  Duration      : " + to_string(total_sec) + " s");
    print("");
    print("============================================================");
}
