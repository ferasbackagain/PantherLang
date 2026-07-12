panther main {
    import panther.core as core;
    import panther.math as math;
    import panther.text as text;
    import panther.net as net;
    import panther.database as db;
    import panther.crypto as crypto;

    let absolute_value = math.abs(-42);
    let message = text.trim("  PantherLang  ");
    let local_address = net.local_ip();
    let connection = db.open(":memory:");
    let digest = crypto.sha256("PantherLang");

    print message;
    print core.to_string(absolute_value);
    print local_address;
    print digest;

    db.close(connection);
}