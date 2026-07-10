panther main {
    fn net_is_loopback_ip(ip) {
        if starts_with(ip, "127.") {
            return true;
        }
        return false;
    }

    fn net_is_link_local_ip(ip) {
        if starts_with(ip, "169.254.") {
            return true;
        }
        return false;
    }

    fn net_is_private_ip(ip) {
        if starts_with(ip, "10.") {
            return true;
        }

        if starts_with(ip, "192.168.") {
            return true;
        }

        if starts_with(ip, "127.") {
            return true;
        }

        if starts_with(ip, "172.16.") {
            return true;
        }
        if starts_with(ip, "172.17.") {
            return true;
        }
        if starts_with(ip, "172.18.") {
            return true;
        }
        if starts_with(ip, "172.19.") {
            return true;
        }
        if starts_with(ip, "172.20.") {
            return true;
        }
        if starts_with(ip, "172.21.") {
            return true;
        }
        if starts_with(ip, "172.22.") {
            return true;
        }
        if starts_with(ip, "172.23.") {
            return true;
        }
        if starts_with(ip, "172.24.") {
            return true;
        }
        if starts_with(ip, "172.25.") {
            return true;
        }
        if starts_with(ip, "172.26.") {
            return true;
        }
        if starts_with(ip, "172.27.") {
            return true;
        }
        if starts_with(ip, "172.28.") {
            return true;
        }
        if starts_with(ip, "172.29.") {
            return true;
        }
        if starts_with(ip, "172.30.") {
            return true;
        }
        if starts_with(ip, "172.31.") {
            return true;
        }

        return false;
    }

    fn net_network_class(ip) {
        if net_is_loopback_ip(ip) {
            return "loopback";
        }

        if net_is_link_local_ip(ip) {
            return "link-local";
        }

        if net_is_private_ip(ip) {
            return "private";
        }

        return "public-or-external";
    }

    fn net_risk_score(ip, open_ports, unknown_nodes, vpn_enabled) {
        let score = 0;

        if net_network_class(ip) == "public-or-external" {
            score = score + 35;
        }

        if net_network_class(ip) == "link-local" {
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

    fn net_security_label(score) {
        if score >= 60 {
            return "HIGH";
        }

        if score >= 30 {
            return "MEDIUM";
        }

        return "LOW";
    }

    fn net_release_summary(ip, score) {
        return "network=" + net_network_class(ip) + ";risk=" + net_security_label(score);
    }
}
