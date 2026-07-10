panther main {
    fn net_port_to_service_name(port) {
        if port == 7 { return "echo"; }
        if port == 9 { return "discard"; }
        if port == 13 { return "daytime"; }
        if port == 19 { return "chargen"; }
        if port == 21 { return "ftp"; }
        if port == 22 { return "ssh"; }
        if port == 23 { return "telnet"; }
        if port == 25 { return "smtp"; }
        if port == 37 { return "time"; }
        if port == 53 { return "dns"; }
        if port == 67 { return "dhcp-server"; }
        if port == 68 { return "dhcp-client"; }
        if port == 69 { return "tftp"; }
        if port == 70 { return "gopher"; }
        if port == 79 { return "finger"; }
        if port == 80 { return "http"; }
        if port == 88 { return "kerberos"; }
        if port == 110 { return "pop3"; }
        if port == 111 { return "rpcbind"; }
        if port == 113 { return "ident"; }
        if port == 119 { return "nntp"; }
        if port == 123 { return "ntp"; }
        if port == 135 { return "msrpc"; }
        if port == 137 { return "netbios-ns"; }
        if port == 138 { return "netbios-dgm"; }
        if port == 139 { return "netbios-ssn"; }
        if port == 143 { return "imap"; }
        if port == 161 { return "snmp"; }
        if port == 162 { return "snmptrap"; }
        if port == 179 { return "bgp"; }
        if port == 194 { return "irc"; }
        if port == 389 { return "ldap"; }
        if port == 443 { return "https"; }
        if port == 445 { return "smb"; }
        if port == 465 { return "smtps"; }
        if port == 500 { return "ipsec"; }
        if port == 514 { return "syslog"; }
        if port == 515 { return "printer"; }
        if port == 520 { return "rip"; }
        if port == 543 { return "klogin"; }
        if port == 544 { return "kshell"; }
        if port == 546 { return "dhcpv6-client"; }
        if port == 547 { return "dhcpv6-server"; }
        if port == 554 { return "rtsp"; }
        if port == 587 { return "submission"; }
        if port == 631 { return "ipp"; }
        if port == 636 { return "ldaps"; }
        if port == 853 { return "dot"; }
        if port == 989 { return "ftps-data"; }
        if port == 990 { return "ftps"; }
        if port == 992 { return "telnets"; }
        if port == 993 { return "imaps"; }
        if port == 994 { return "ircs"; }
        if port == 995 { return "pop3s"; }
        if port == 1433 { return "mssql"; }
        if port == 1521 { return "oracle-db"; }
        if port == 1701 { return "l2tp"; }
        if port == 1723 { return "pptp"; }
        if port == 1812 { return "radius"; }
        if port == 1813 { return "radius-acct"; }
        if port == 1883 { return "mqtt"; }
        if port == 1900 { return "ssdp"; }
        if port == 2049 { return "nfs"; }
        if port == 2082 { return "cpanel"; }
        if port == 2083 { return "cpanels"; }
        if port == 2086 { return "whm"; }
        if port == 2087 { return "whms"; }
        if port == 2095 { return "cpanel-webmail"; }
        if port == 2096 { return "cpanel-webmails"; }
        if port == 2181 { return "zookeeper"; }
        if port == 2375 { return "docker"; }
        if port == 2376 { return "docker-tls"; }
        if port == 2379 { return "etcd"; }
        if port == 2380 { return "etcd-peer"; }
        if port == 2483 { return "oracle-db-ssl"; }
        if port == 2484 { return "oracle-db-ssl2"; }
        if port == 3000 { return "goget"; }
        if port == 3128 { return "squid"; }
        if port == 3306 { return "mysql"; }
        if port == 3389 { return "rdp"; }
        if port == 3478 { return "stun"; }
        if port == 3479 { return "stun-behavior"; }
        if port == 3480 { return "stun-tests"; }
        if port == 3690 { return "svn"; }
        if port == 3799 { return "radius-dyn-auth"; }
        if port == 4222 { return "nats"; }
        if port == 4333 { return "ahcp"; }
        if port == 4369 { return "erpc"; }
        if port == 4443 { return "phar"; }
        if port == 4500 { return "ipsec-nat-t"; }
        if port == 4567 { return "sinatra"; }
        if port == 4569 { return "iax"; }
        if port == 4646 { return "concurrent"; }
        if port == 4672 { return "rfa"; }
        if port == 4750 { return "realserver"; }
        if port == 4800 { return "iconv"; }
        if port == 4848 { return "glassfish"; }
        if port == 4899 { return "radmin"; }
        if port == 4911 { return "grinder"; }
        if port == 4949 { return "munin"; }
        if port == 5000 { return "upnp"; }
        if port == 5001 { return "plex"; }
        if port == 5002 { return "ssh-mgmt"; }
        if port == 5003 { return "filemaker"; }
        if port == 5004 { return "avt-profile1"; }
        if port == 5005 { return "avt-profile2"; }
        if port == 5038 { return "asterisk"; }
        if port == 5050 { return "mmcc"; }
        if port == 5060 { return "sip"; }
        if port == 5061 { return "sips"; }
        if port == 5070 { return "sip-tls"; }
        if port == 5080 { return "sip-udp"; }
        if port == 5222 { return "xmpp"; }
        if port == 5223 { return "xmpps"; }
        if port == 5349 { return "stuns"; }
        if port == 5351 { return "nat-pmp"; }
        if port == 5353 { return "mdns"; }
        if port == 5432 { return "postgresql"; }
        if port == 5445 { return "smbdirect"; }
        if port == 5450 { return "tie"; }
        if port == 5495 { return "vnc-tcp"; }
        if port == 5500 { return "vnc-http"; }
        if port == 5554 { return "sip-rtp"; }
        if port == 5555 { return "adb"; }
        if port == 5560 { return "moxa-io"; }
        if port == 5601 { return "kibana"; }
        if port == 5631 { return "pcanywhere-data"; }
        if port == 5632 { return "pcanywhere-stat"; }
        if port == 5666 { return "nrpe"; }
        if port == 5667 { return "nsca"; }
        if port == 5672 { return "amqp"; }
        if port == 5678 { return "amqp-tls"; }
        if port == 5683 { return "coap"; }
        if port == 5858 { return "vnc-rfb"; }
        if port == 5900 { return "vnc"; }
        if port == 5901 { return "vnc-1"; }
        if port == 5984 { return "couchdb"; }
        if port == 6000 { return "x11"; }
        if port == 6001 { return "x11-1"; }
        if port == 6379 { return "redis"; }
        if port == 6443 { return "kubernetes"; }
        if port == 6480 { return "cassandra"; }
        if port == 6543 { return "pgsync"; }
        if port == 6666 { return "ircd"; }
        if port == 6667 { return "ircd-ssl"; }
        if port == 6668 { return "ircd-ssl-alt"; }
        if port == 6697 { return "ircs-alt"; }
        if port == 6789 { return "cassandra-thrift"; }
        if port == 6881 { return "bittorrent"; }
        if port == 7001 { return "weblogic"; }
        if port == 7002 { return "weblogic-ssl"; }
        if port == 7077 { return "mesos"; }
        if port == 8000 { return "http-alt"; }
        if port == 8008 { return "http-alt2"; }
        if port == 8009 { return "ajp13"; }
        if port == 8042 { return "hue"; }
        if port == 8069 { return "odoo"; }
        if port == 8080 { return "http-proxy"; }
        if port == 8081 { return "http-proxy-alt"; }
        if port == 8082 { return "http-proxy-alt2"; }
        if port == 8086 { return "influxdb"; }
        if port == 8087 { return "influxdb-udp"; }
        if port == 8088 { return "http-proxy-alt3"; }
        if port == 8089 { return "splunkd"; }
        if port == 8090 { return "http-proxy-alt4"; }
        if port == 8091 { return "couchbase"; }
        if port == 8092 { return "couchbase-api"; }
        if port == 8096 { return "emby"; }
        if port == 8100 { return "trident"; }
        if port == 8111 { return "skype"; }
        if port == 8123 { return "polipo"; }
        if port == 8140 { return "puppet"; }
        if port == 8172 { return "mssql-mon"; }
        if port == 8181 { return "websphere"; }
        if port == 8200 { return "vmware-vc"; }
        if port == 8222 { return "vmware-vc-ssl"; }
        if port == 8243 { return "https-alt"; }
        if port == 8280 { return "http-alt5"; }
        if port == 8300 { return "tftp-alt"; }
        if port == 8332 { return "bitcoin"; }
        if port == 8333 { return "bitcoin-testnet"; }
        if port == 8384 { return "syncthing"; }
        if port == 8400 { return "cvspserver"; }
        if port == 8443 { return "https-alt2"; }
        if port == 8500 { return "consul"; }
        if port == 8530 { return "dns-over-https"; }
        if port == 8531 { return "dns-over-https2"; }
        if port == 8545 { return "ethereum-rpc"; }
        if port == 8649 { return "ganglia"; }
        if port == 8651 { return "ganglia-meta"; }
        if port == 8761 { return "eureka"; }
        if port == 8787 { return "openfire"; }
        if port == 9000 { return "cups"; }
        if port == 9001 { return "tor"; }
        if port == 9002 { return "tor-control"; }
        if port == 9009 { return "pichat"; }
        if port == 9042 { return "cassandra-native"; }
        if port == 9043 { return "websphere-admin"; }
        if port == 9050 { return "tor-socks"; }
        if port == 9090 { return "cockpit"; }
        if port == 9092 { return "kafka"; }
        if port == 9100 { return "jetdirect"; }
        if port == 9110 { return "nfs-rpc"; }
        if port == 9150 { return "tor-control-alt"; }
        if port == 9160 { return "cassandra-thrift2"; }
        if port == 9200 { return "elasticsearch"; }
        if port == 9300 { return "elasticsearch-cluster"; }
        if port == 9418 { return "git"; }
        if port == 9999 { return "abyss"; }
        if port == 10000 { return "webmin"; }
        if port == 10001 { return "nfs-lock"; }
        if port == 10009 { return "crossfire"; }
        if port == 10010 { return "nfs-quota"; }
        if port == 10050 { return "zabbix-agent"; }
        if port == 10051 { return "zabbix-server"; }
        if port == 10113 { return "netiq"; }
        if port == 10114 { return "netiq-ssl"; }
        if port == 10161 { return "snmp-agent"; }
        if port == 10162 { return "snmp-trap"; }
        if port == 10180 { return "gnutella"; }
        if port == 10243 { return "ms-wbt"; }
        if port == 10389 { return "hadoop"; }
        if port == 10443 { return "cirrus"; }
        if port == 10554 { return "vnc-rfb-alt"; }
        if port == 10666 { return "insta-irc"; }
        if port == 11000 { return "vnc-sesman"; }
        if port == 11001 { return "vnc-sesman-ssl"; }
        if port == 11111 { return "vnc-hot"; }
        if port == 11211 { return "memcached"; }
        if port == 11214 { return "memcached-udp"; }
        if port == 11371 { return "hkp"; }
        if port == 11443 { return "hkip"; }
        if port == 12000 { return "ccproxy"; }
        if port == 12001 { return "nfs-rquota"; }
        if port == 12174 { return "utp"; }
        if port == 12200 { return "vrv"; }
        if port == 12345 { return "netbus"; }
        if port == 12443 { return "https-mitm"; }
        if port == 12975 { return "logmein"; }
        if port == 13000 { return "gpsd"; }
        if port == 13001 { return "gpsd-ssl"; }
        if port == 13075 { return "mindset"; }
        if port == 13131 { return "kvs"; }
        if port == 13223 { return "powwow"; }
        if port == 13579 { return "omniorb"; }
        if port == 13666 { return "dns2"; }
        if port == 13720 { return "bprd"; }
        if port == 13721 { return "bpdbm"; }
        if port == 13722 { return "bpjava"; }
        if port == 13724 { return "bprd-vnet"; }
        if port == 13782 { return "bpcd"; }
        if port == 13783 { return "vnetd"; }
        if port == 13785 { return "nbdb"; }
        if port == 13786 { return "nbdb-admin"; }
        if port == 13830 { return "ceton"; }
        if port == 13832 { return "dms"; }
        if port == 13900 { return "cups-alt"; }
        if port == 13980 { return "arcserve"; }
        if port == 14000 { return "suse-mgr"; }
        if port == 14001 { return "suse-mgr-ssl"; }
        if port == 14033 { return "sage"; }
        if port == 14141 { return "boinc"; }
        if port == 14142 { return "boinc-mgr"; }
        if port == 14143 { return "boinc-remote"; }
        if port == 14145 { return "boinc-filexfer"; }
        if port == 14149 { return "boinc-sched"; }
        if port == 14150 { return "boinc-trans"; }
        if port == 14534 { return "armix"; }
        if port == 14621 { return "swp"; }
        if port == 14892 { return "netref"; }
        if port == 14900 { return "kde"; }
        if port == 15000 { return "hydranode"; }
        if port == 15001 { return "hydranode-ssl"; }
        if port == 15002 { return "hydranode-udp"; }
        if port == 15118 { return "v2g"; }
        if port == 15345 { return "xpilot"; }
        if port == 15363 { return "3par"; }
        if port == 15555 { return "cisco-ips"; }
        if port == 15660 { return "beacon"; }
        if port == 15740 { return "ptp"; }
        if port == 15999 { return "prime"; }
        if port == 16000 { return "oracle-db-rdb"; }
        if port == 16001 { return "oracle-db-rdb-ssl"; }
        if port == 16010 { return "oracle-db-rdb-udp"; }
        if port == 16016 { return "oracle-db-rdb-ssl-udp"; }
        if port == 16020 { return "oracle-db-rdb-rdma"; }
        if port == 16021 { return "oracle-db-rdb-rdma-ssl"; }
        if port == 16111 { return "nfs-rquota-ssl"; }
        if port == 16112 { return "nfs-rquota-ssl-udp"; }
        if port == 16200 { return "oracle-db-rdb-shared"; }
        if port == 16201 { return "oracle-db-rdb-shared-ssl"; }
        if port == 16250 { return "nfs-rdma"; }
        if port == 16360 { return "netsnap"; }
        if port == 16361 { return "netsnap-ssl"; }
        if port == 16384 { return "cvd"; }
        if port == 16385 { return "cvd-ssl"; }
        if port == 16621 { return "icp"; }
        if port == 16622 { return "icp-ssl"; }
        if port == 16660 { return "ace"; }
        if port == 16661 { return "ace-ssl"; }
        if port == 16789 { return "rea"; }
        if port == 16880 { return "ivs"; }
        if port == 17000 { return "soundminer"; }
        if port == 17001 { return "soundminer-ssl"; }
        if port == 17185 { return "vdm"; }
        if port == 17219 { return "chipper"; }
        if port == 17220 { return "chipper-ssl"; }
        if port == 17221 { return "chipper-udp"; }
        if port == 17222 { return "chipper-ssl-udp"; }
        if port == 17223 { return "chipper-dtls"; }
        if port == 17300 { return "kuber"; }
        if port == 17301 { return "kuber-ssl"; }
        if port == 17302 { return "kuber-udp"; }
        if port == 17303 { return "kuber-ssl-udp"; }
        if port == 17304 { return "kuber-dtls"; }
        if port == 17400 { return "sstp"; }
        if port == 17401 { return "sstp-ssl"; }
        if port == 17500 { return "db-lsp"; }
        if port == 17501 { return "db-lsp-ssl"; }
        if port == 17600 { return "msmq"; }
        if port == 17601 { return "msmq-ssl"; }
        if port == 17777 { return "nsrexec"; }
        if port == 18000 { return "biim"; }
        if port == 18001 { return "biim-ssl"; }
        if port == 18181 { return "opsec"; }
        if port == 18182 { return "opsec-ssl"; }
        if port == 18183 { return "opsec-udp"; }
        if port == 18184 { return "opsec-ssl-udp"; }
        if port == 18185 { return "opsec-dtls"; }
        if port == 18200 { return "oracle-db-rdb-cluster"; }
        if port == 18201 { return "oracle-db-rdb-cluster-ssl"; }
        if port == 18210 { return "oracle-db-rdb-cluster-udp"; }
        if port == 18211 { return "oracle-db-rdb-cluster-ssl-udp"; }
        if port == 18212 { return "oracle-db-rdb-cluster-dtls"; }
        if port == 18300 { return "oracle-db-rdb-cluster-rdma"; }
        if port == 18301 { return "oracle-db-rdb-cluster-rdma-ssl"; }
        if port == 18400 { return "oracle-db-rdb-cluster-shared"; }
        if port == 18401 { return "oracle-db-rdb-cluster-shared-ssl"; }
        if port == 18500 { return "oracle-db-rdb-cluster-shared-udp"; }
        if port == 18501 { return "oracle-db-rdb-cluster-shared-ssl-udp"; }
        if port == 18600 { return "oracle-db-rdb-cluster-shared-dtls"; }
        if port == 18601 { return "oracle-db-rdb-cluster-shared-dtls-ssl"; }
        if port == 18700 { return "oracle-db-rdb-cluster-shared-rdma"; }
        if port == 18701 { return "oracle-db-rdb-cluster-shared-rdma-ssl"; }
        if port == 18800 { return "oracle-db-rdb-cluster-shared-rdma-shared"; }
        if port == 18801 { return "oracle-db-rdb-cluster-shared-rdma-shared-ssl"; }
        if port == 18900 { return "oracle-db-rdb-active-data-guard"; }
        if port == 18901 { return "oracle-db-rdb-active-data-guard-ssl"; }
        if port == 19000 { return "oracle-db-rdb-active-data-guard-udp"; }
        if port == 19001 { return "oracle-db-rdb-active-data-guard-ssl-udp"; }
        if port == 19100 { return "oracle-db-rdb-active-data-guard-dtls"; }
        if port == 19101 { return "oracle-db-rdb-active-data-guard-dtls-ssl"; }
        if port == 19200 { return "oracle-db-rdb-active-data-guard-rdma"; }
        if port == 19201 { return "oracle-db-rdb-active-data-guard-rdma-ssl"; }
        if port == 19300 { return "oracle-db-rdb-active-data-guard-rdma-shared"; }
        if port == 19301 { return "oracle-db-rdb-active-data-guard-rdma-shared-ssl"; }
        if port == 19400 { return "oracle-db-rdb-active-data-guard-rdma-shared-dtls"; }
        if port == 19401 { return "oracle-db-rdb-active-data-guard-rdma-shared-dtls-ssl"; }
        if port == 19410 { return "oracle-db-rdb-active-data-guard-rdma-shared-rdma"; }
        if port == 19411 { return "oracle-db-rdb-active-data-guard-rdma-shared-rdma-ssl"; }
        if port == 19500 { return "oracle-db-rdb-far-sync"; }
        if port == 19501 { return "oracle-db-rdb-far-sync-ssl"; }
        return "unknown";
    }

    fn net_service_confidence(port, observed_data) {
        if port == 22 {
            if contains(observed_data, "SSH") {
                return "high";
            }
            if contains(observed_data, "ssh") {
                return "high";
            }
            return "medium";
        }
        if port == 80 {
            if contains(observed_data, "HTTP") {
                return "high";
            }
            if contains(observed_data, "http") {
                return "high";
            }
            return "medium";
        }
        if port == 443 {
            return "medium";
        }
        if observed_data == "" {
            return "low";
        }
        return "medium";
    }

    fn net_is_well_known_port(port) {
        if port < 1024 {
            return true;
        }
        return false;
    }

    fn net_infer_service(port, banner, reverse_dns_name) {
        let svc = net_port_to_service_name(port);
        let confidence = net_service_confidence(port, banner);
        if svc != "unknown" {
            if confidence == "high" {
                return {service: svc, confidence: confidence, evidence: "port+banner"};
            }
            if reverse_dns_name != "" {
                if contains(reverse_dns_name, svc) {
                    return {service: svc, confidence: "high", evidence: "port+dns"};
                }
            }
            return {service: svc, confidence: confidence, evidence: "port"};
        }
        if banner != "" {
            if contains(banner, "HTTP") {
                return {service: "http", confidence: "medium", evidence: "banner"};
            }
            if contains(banner, "SSH") {
                return {service: "ssh", confidence: "medium", evidence: "banner"};
            }
            return {service: "unknown", confidence: "low", evidence: "banner"};
        }
        return {service: "unknown", confidence: "low", evidence: "none"};
    }

    fn net_probe_http(target, port, timeout_ms) {
        let raw = tcp_banner(target, port, timeout_ms);
        if raw == "" {
            return {http: false, banner: "", server: "", status: 0};
        }
        let is_http = false;
        let server = "";
        let status = 0;
        if contains(raw, "HTTP") {
            is_http = true;
        }
        if contains(raw, "Server:") {
            let parts = split(raw, "Server:");
            if len(parts) > 1 {
                let svr_parts = split(parts[1], "\\n");
                server = svr_parts[0];
            }
        }
        return {http: is_http, banner: raw, server: server, status: status};
    }

    fn net_format_service_result(target, port_num, state, latency, banner) {
        let svc_info = net_infer_service(port_num, banner, net_reverse_resolve(target));
        let dns = net_reverse_resolve(target);
        return {
            target: target,
            port: port_num,
            state: state,
            latency_ms: latency,
            service: svc_info.service,
            confidence: svc_info.confidence,
            evidence: svc_info.evidence,
            banner: banner,
            reverse_dns: dns
        };
    }
}
