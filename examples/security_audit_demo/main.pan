panther main {
    print "PantherLang Security Audit Demo";
    print "Mode: Defensive security analysis only";
    print "";

    print "Path Audit:";
    print "  /etc/passwd -> BLOCKED (sensitive path)";
    print "  /tmp/test.txt -> ALLOWED (within sandbox)";
    print "  /home/user/.ssh/id_rsa -> BLOCKED (sensitive path)";
    print "";

    print "Secret Detection Demo:";
    print "  [REDACTED] Potential API key detected (sk-****)";
    print "  OK: This is a normal log message";
    print "  [REDACTED] Potential password detected";
    print "  [REDACTED] Potential API key detected (sk-****)";
    print "";

    let paths_scanned = 3;
    let secrets_scanned = 4;
    let unauthorized = 0;

    print "Audit Summary:";
    print "  Paths scanned: " + string(paths_scanned);
    print "  Secrets scanned: " + string(secrets_scanned);
    print "  Unauthorized access: " + string(unauthorized);
    print "Defensive audit complete.";
}
