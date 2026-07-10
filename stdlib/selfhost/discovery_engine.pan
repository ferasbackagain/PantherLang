panther main {
    fn net_discover_host(target, ports, timeout_ms) {
        let results = [];
        let n = len(ports);
        for i in 0..(n - 1) {
            let port = ports[i];
            let start = time_now();
            let state = tcp_connect(target, port, timeout_ms);
            let elapsed_ms = to_int((time_now() - start) * 1000);
            let result = {
                target: target,
                port: port,
                state: state,
                latency_ms: elapsed_ms,
                service: "",
                banner: "",
                confidence: ""
            };
            array_push(results, result);
        }
        return results;
    }

    fn net_open_ports(results) {
        let open = [];
        let n = len(results);
        for i in 0..(n - 1) {
            if results[i].state == "open" {
                array_push(open, results[i]);
            }
        }
        return open;
    }

    fn net_open_ports_with_services(results) {
        let enhanced = [];
        let n = len(results);
        for i in 0..(n - 1) {
            let r = results[i];
            let svc = net_port_to_service_name(r.port);
            let enriched = {
                target: r.target,
                port: r.port,
                state: r.state,
                latency_ms: r.latency_ms,
                service: svc,
                banner: "",
                confidence: ""
            };
            array_push(enhanced, enriched);
        }
        return enhanced;
    }

    fn net_collect_banners(target, open_results, timeout_ms) {
        let with_banners = [];
        let n = len(open_results);
        for i in 0..(n - 1) {
            let r = open_results[i];
            let banner = tcp_banner(target, r.port, timeout_ms);
            let confidence = "low";
            if banner != "" {
                confidence = net_service_confidence(r.port, banner);
            }
            let enriched = {
                target: r.target,
                port: r.port,
                state: r.state,
                latency_ms: r.latency_ms,
                service: r.service,
                banner: banner,
                confidence: confidence
            };
            array_push(with_banners, enriched);
        }
        return with_banners;
    }

    fn net_scan_host(target, ports, connect_timeout_ms, banner_timeout_ms) {
        let raw = net_discover_host(target, ports, connect_timeout_ms);
        let open = net_open_ports(raw);
        let with_svcs = net_open_ports_with_services(open);
        let with_banners = net_collect_banners(target, with_svcs, banner_timeout_ms);
        let summary = {
            target: target,
            total_ports: len(ports),
            open_count: len(with_banners),
            closed_count: len(ports) - len(with_banners),
            results: with_banners
        };
        return summary;
    }

    fn net_local_system_info() {
        return {
            hostname: system_hostname(),
            platform: system_os(),
            primary_ip: net_primary_ip(),
            gateway: net_gateway()
        };
    }

    fn net_format_result(r) {
        let line = to_string(r.port) + "/tcp  State: " + r.state;
        if r.latency_ms > 0 {
            line = line + "  Latency: " + to_string(r.latency_ms) + " ms";
        }
        if r.service != "" {
            line = line + "  Service: " + r.service;
        }
        if r.banner != "" {
            line = line + "  Banner: " + r.banner;
        }
        if r.confidence != "" {
            line = line + "  Confidence: " + r.confidence;
        }
        return line;
    }
}
