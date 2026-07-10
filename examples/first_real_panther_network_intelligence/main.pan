panther main {
    let hostname = system_hostname();
    let detected_ip = net_local_ip();
    let gateway = net_gateway();
    let dns = net_dns_servers();
    let interfaces = net_interfaces();
    let neighbors = net_neighbors();

    print "============================================================";
    print "        PantherLang Real Network Intelligence";
    print "============================================================";
    print "";
    print "[ HOST IDENTITY ]";
    print "Hostname       : " + to_string(hostname);
    print "Local IP       : " + to_string(detected_ip);
    print "";
    print "[ NETWORK CORE ]";
    print "Gateway        : " + to_string(gateway);
    print "DNS Servers    : " + to_string(dns);
    print "";
    print "[ INTERFACES ]";
    print to_string(interfaces);
    print "";
    print "[ PASSIVE NEIGHBORS ]";
    print to_string(neighbors);
    print "";
    print "[ LOCAL SERVICE PROBES ]";
    print "127.0.0.1:22   : " + to_string(tcp_connect("127.0.0.1", 22, 500));
    print "127.0.0.1:80   : " + to_string(tcp_connect("127.0.0.1", 80, 500));
    print "127.0.0.1:443  : " + to_string(tcp_connect("127.0.0.1", 443, 500));
    print "";
    print "[ EXECUTION MODEL ]";
    print "Language       : PantherLang";
    print "Policy         : passive local discovery + explicit localhost probes";
    print "External nmap  : not invoked by this example";
    print "============================================================";
}
