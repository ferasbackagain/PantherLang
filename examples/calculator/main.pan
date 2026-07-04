panther main {

    print "======================================";
    print "     Panther Security Audit Report";
    print "======================================";

    let report = {
        title: "Defensive Security Audit",
        host: "kali-panther",
        os: "Kali Linux",
        scope: "Local authorized system",
        mode: "Read-only assessment",
        status: "PASS"
    };

    print report["title"];
    print report["host"];
    print report["os"];
    print report["scope"];
    print report["mode"];

    print "";
    print "SYSTEM BASELINE";
    print "----------------------";

    let system = {
        firewall: "Enabled",
        updates: "Review required",
        disk_encryption: "Recommended",
        backups: "Configured",
        antivirus: "Not applicable / Linux",
        user_privileges: "Standard user preferred"
    };

    print "Firewall:";
    print system["firewall"];
    print "Updates:";
    print system["updates"];
    print "Disk encryption:";
    print system["disk_encryption"];
    print "Backups:";
    print system["backups"];
    print "Antivirus:";
    print system["antivirus"];
    print "User privileges:";
    print system["user_privileges"];

    print "";
    print "NETWORK BASELINE";
    print "----------------------";

    let network = {
        interface: "wlan0",
        ip: "192.168.1.25",
        gateway: "192.168.1.1",
        dns: "Review required",
        open_ports: 3,
        unknown_devices: 0
    };

    print "Interface:";
    print network["interface"];
    print "IP:";
    print network["ip"];
    print "Gateway:";
    print network["gateway"];
    print "DNS:";
    print network["dns"];
    print "Open ports:";
    print network["open_ports"];
    print "Unknown devices:";
    print network["unknown_devices"];

    print "";
    print "FILE INTEGRITY BASELINE";
    print "----------------------";

    let files = [
        { path: "/etc/passwd", status: "Monitor", risk: "Medium" },
        { path: "/etc/ssh/sshd_config", status: "Review", risk: "High" },
        { path: "/home/panther/.ssh", status: "Check permissions", risk: "High" }
    ];

    print "File:";
    print files[0]["path"];
    print files[0]["status"];
    print files[0]["risk"];

    print "File:";
    print files[1]["path"];
    print files[1]["status"];
    print files[1]["risk"];

    print "File:";
    print files[2]["path"];
    print files[2]["status"];
    print files[2]["risk"];

    print "";
    print "SECURITY FINDINGS";
    print "----------------------";

    let finding1 = {
        id: "SEC-001",
        title: "Review SSH configuration",
        severity: "High",
        recommendation: "Disable password login if key-based auth is available"
    };

    let finding2 = {
        id: "SEC-002",
        title: "Validate DNS configuration",
        severity: "Medium",
        recommendation: "Use trusted DNS and monitor changes"
    };

    let finding3 = {
        id: "SEC-003",
        title: "Enable full disk encryption",
        severity: "Medium",
        recommendation: "Protect local data at rest"
    };

    print finding1["id"];
    print finding1["title"];
    print finding1["severity"];
    print finding1["recommendation"];

    print finding2["id"];
    print finding2["title"];
    print finding2["severity"];
    print finding2["recommendation"];

    print finding3["id"];
    print finding3["title"];
    print finding3["severity"];
    print finding3["recommendation"];

    print "";
    print "RISK SCORE";
    print "----------------------";

    let high = 2;
    let medium = 2;
    let low = 0;
    let score = high * 10 + medium * 5 + low;

    print "High findings:";
    print high;
    print "Medium findings:";
    print medium;
    print "Low findings:";
    print low;
    print "Risk score:";
    print score;

    if score >= 30 {
        print "Overall risk: HIGH";
    } else {
        if score >= 15 {
            print "Overall risk: MEDIUM";
        } else {
            print "Overall risk: LOW";
        }
    }

    print "";
    print "DEFENSIVE ACTION PLAN";
    print "----------------------";

    let actions = [
        "Review SSH settings",
        "Check file permissions",
        "Confirm backups",
        "Update packages",
        "Review network devices"
    ];

    print actions[0];
    print actions[1];
    print actions[2];
    print actions[3];
    print actions[4];

    print "";
    print "COMPLIANCE NOTES";
    print "----------------------";
    print "This report is defensive only.";
    print "Run only on systems you own or are authorized to assess.";
    print "No exploitation, credential access, persistence, or evasion is performed.";

    print "";
    print "======================================";
    print " Security Audit Report Complete";
    print "======================================";
}
