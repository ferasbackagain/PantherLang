panther main {
    // Network configuration
    fn panther_net_local_ip() {
        return net_local_ip();
    }

    fn panther_net_primary_ip() {
        return net_primary_ip();
    }

    fn panther_net_gateway() {
        return net_gateway();
    }

    fn panther_net_dns() {
        return net_dns();
    }

    fn panther_net_dns_servers() {
        return net_dns_servers();
    }

    fn panther_net_interfaces() {
        return net_interfaces();
    }

    fn panther_net_mac_address(interface) {
        return net_mac_address(interface);
    }

    fn panther_net_resolve(host) {
        return net_resolve(host);
    }

    fn panther_net_reverse_resolve(ip) {
        return net_reverse_resolve(ip);
    }

    fn panther_net_is_private_ip(ip) {
        return net_is_private_ip(ip);
    }

    fn panther_net_local_ips() {
        return net_local_ips();
    }

    fn panther_net_neighbors() {
        return net_neighbors();
    }

    // Port checking
    fn panther_net_port_check(host, port, timeout) {
        return net_port_check(host, port, timeout);
    }

    fn panther_net_port_open(host, port) {
        return net_port_check(host, port) == "open";
    }

    fn panther_net_ping(host) {
        return net_ping(host);
    }

    fn panther_net_scan_lan() {
        return net_scan_lan();
    }

    // TCP operations
    fn panther_net_tcp_connect(host, port, timeout_ms) {
        return tcp_connect(host, port, timeout_ms);
    }

    fn panther_net_tcp_banner(host, port, timeout_ms) {
        return tcp_banner(host, port, timeout_ms);
    }

    fn panther_net_tcp_send(host, port, data, timeout) {
        return net_tcp_send(host, port, data, timeout);
    }

    fn panther_net_tcp_serve_start(port, response, oneshot) {
        return net_tcp_serve_start(port, response, oneshot);
    }

    fn panther_net_tcp_serve_stop(port) {
        return net_tcp_serve_stop(port);
    }

    fn panther_net_tcp_serve_wait(port, timeout) {
        return net_tcp_serve_wait(port, timeout);
    }

    // UDP operations
    fn panther_net_udp_send(host, port, data, timeout) {
        return net_udp_send(host, port, data, timeout);
    }

    // IP classification helpers (from self-hosted network.pan)
    fn panther_net_is_loopback_ip(ip) {
        if starts_with(ip, "127.") {
            return true;
        }
        return false;
    }

    fn panther_net_is_link_local_ip(ip) {
        if starts_with(ip, "169.254.") {
            return true;
        }
        return false;
    }

    fn panther_net_network_class(ip) {
        if panther_net_is_loopback_ip(ip) {
            return "loopback";
        }
        if panther_net_is_link_local_ip(ip) {
            return "link-local";
        }
        if panther_net_is_private_ip(ip) {
            return "private";
        }
        return "public-or-external";
    }

    fn panther_net_risk_score(ip, open_ports, unknown_nodes, vpn_enabled) {
        let score = 0;
        if panther_net_network_class(ip) == "public-or-external" {
            score = score + 35;
        }
        if panther_net_network_class(ip) == "link-local" {
            score = score + 25;
        }
        if open_ports > 5 {
            score = score + 25;
        }
        if unknown_nodes > 0 {
            score = score + 15;
        }
        if vpn_enabled == false {
            score = score + 10;
        }
        return score;
    }

    fn panther_net_security_label(score) {
        if score >= 60 {
            return "HIGH";
        }
        if score >= 30 {
            return "MEDIUM";
        }
        return "LOW";
    }

    fn panther_net_release_summary(ip, score) {
        return "network=" + panther_net_network_class(ip) + ";risk=" + panther_net_security_label(score);
    }
}