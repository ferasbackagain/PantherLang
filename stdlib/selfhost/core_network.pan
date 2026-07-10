panther main {
    fn resolve_hostname(host) {
        return net_resolve(host);
    }

    fn reverse_lookup(ip) {
        return net_reverse_resolve(ip);
    }

    fn check_port(host, port) {
        return net_port_check(host, port);
    }

    fn is_port_open(host, port) {
        return net_port_check(host, port) == "open";
    }

    fn local_ip() {
        return net_local_ip();
    }

    fn my_interfaces() {
        return net_interfaces();
    }

    fn ping_host(host) {
        return net_ping(host);
    }
}
