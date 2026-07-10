panther main {
    fn net_is_authorized_target(ip) {
        if net_is_loopback_ip(ip) {
            return true;
        }
        if net_is_private_ip(ip) {
            return true;
        }
        return false;
    }

    fn net_scan_profile(target_type) {
        if target_type == "single" {
            return "quick";
        }
        if target_type == "subnet" {
            return "balanced";
        }
        return "conservative";
    }

    fn net_open_port_summary(open_count, total_count) {
        if open_count == 0 {
            return "no-open-ports";
        }
        if open_count == total_count {
            return "all-open";
        }
        if open_count > to_int(total_count / 2) {
            return "mostly-open";
        }
        return "partially-open";
    }

    fn net_timeout_status(total, timed_out) {
        if timed_out == 0 {
            return "no-timeouts";
        }
        if timed_out == total {
            return "all-timed-out";
        }
        if timed_out > to_int(total / 2) {
            return "mostly-timed-out";
        }
        return "partial-timeouts";
    }
}
