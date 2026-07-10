panther main {
    fn net_is_valid_ipv4(ip) {
        let parts = split(ip, ".");
        if len(parts) != 4 {
            return false;
        }
        for i in 0..3 {
            let val = to_int(parts[i]);
            if val < 0 {
                return false;
            }
            if val > 255 {
                return false;
            }
        }
        return true;
    }

    fn net_is_public_ip(ip) {
        if net_is_loopback_ip(ip) {
            return false;
        }
        if net_is_link_local_ip(ip) {
            return false;
        }
        if net_is_private_ip(ip) {
            return false;
        }
        return true;
    }

    fn net_normalize_ip(ip) {
        if net_is_valid_ipv4(ip) {
            return ip;
        }
        let resolved = net_resolve(ip);
        if resolved != "" {
            return resolved;
        }
        return ip;
    }
}
