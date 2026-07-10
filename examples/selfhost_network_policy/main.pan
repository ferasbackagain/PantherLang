panther main {
    let primary = net_local_ip();
    let class_name = net_network_class(primary);
    let risk = net_risk_score(primary, 3, 0, false);

    print "==================================================";
    print "        PantherLang Self-Hosted Network Policy";
    print "==================================================";
    print "Primary IP      : " + primary;
    print "Network class   : " + class_name;
    print "Risk score      : " + to_string(risk);
    print "Risk label      : " + net_security_label(risk);
    print "Policy summary  : " + net_release_summary(primary, risk);
    print "Logic source    : stdlib/selfhost/network.pan";
    print "Host primitive  : net_local_ip()";
    print "==================================================";
}
