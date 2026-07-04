panther main {
    print "================================================";
    print " PantherLang Stdlib S1-S6 Release Contract";
    print "================================================";

    print "S1 TYPES AND IO";
    print type_of(45);
    print type_of("Panther");
    print type_of(true);
    print to_string(45) + " Panther";
    print to_int("50") + 5;
    print to_number("60") + 10;
    print to_float("3.5") + 1.5;
    print to_bool("true");
    print println("Panther", "Stdlib", "Ready");
    print printf("Hello {}", "Panther");

    print "S2 FILESYSTEM";
    print fs_mkdir(".panther_tmp/stdlib_contract");
    print fs_write(".panther_tmp/stdlib_contract/sample.txt", "Panther FS OK");
    print fs_append(".panther_tmp/stdlib_contract/sample.txt", " + append");
    print fs_exists(".panther_tmp/stdlib_contract/sample.txt");
    print fs_read(".panther_tmp/stdlib_contract/sample.txt");
    print type_of(fs_listdir(".panther_tmp/stdlib_contract"));
    print type_of(fs_cwd());
    print type_of(fs_absolute(".panther_tmp/stdlib_contract/sample.txt"));

    print "S3 SYSTEM TIME RANDOM";
    print type_of(system_hostname());
    print type_of(system_os());
    print type_of(system_arch());
    print type_of(system_username());
    print type_of(system_cpu_count());
    print type_of(system_memory());
    print type_of(system_disk("."));
    print type_of(system_cwd());
    print type_of(system_pid());
    print type_of(time_now());
    print type_of(random_float());
    print type_of(random_int(1, 3));

    print "S4 NET HTTP JSON SQLITE";
    print type_of(net_local_ip());
    print type_of(net_gateway());
    print type_of(net_dns());
    print type_of(net_interfaces());
    print type_of(net_mac_address());
    print type_of(net_resolve("localhost"));
    print type_of(net_port_check("127.0.0.1", 1, 0.1));
    print type_of(net_scan_lan());

    let obj = json_parse("{\"name\": \"Panther\", \"ok\": true}");
    print obj["name"];
    print json_valid("{\"ok\": true}");
    print type_of(json_stringify(obj));
    print type_of(json_pretty(obj));

    let http_result = http_request("GET", "http://127.0.0.1:1", "", 0.1);
    print type_of(http_result);

    let conn = sqlite_open(".panther_tmp/stdlib_contract/test.db");
    print type_of(conn);
    print sqlite_execute(conn, "CREATE TABLE IF NOT EXISTS items (name TEXT)");
    print sqlite_execute(conn, "DELETE FROM items");
    print sqlite_execute(conn, "INSERT INTO items (name) VALUES ('Panther')");
    print type_of(sqlite_query(conn, "SELECT name FROM items"));
    print sqlite_close(conn);

    print "S5 CRYPTO";
    print type_of(crypto_sha256("Panther"));
    print type_of(crypto_sha512("Panther"));
    print type_of(crypto_md5("Panther"));
    print type_of(crypto_hmac_sha256("key", "message"));
    print type_of(crypto_uuid());
    print type_of(crypto_random_bytes(8));
    print type_of(crypto_secure_random_int(1, 10));
    print crypto_base64_decode(crypto_base64_encode("Panther"));
    print crypto_hex_decode(crypto_hex_encode("Panther"));

    print "S6 AI";
    print type_of(ai_supported_providers());
    print type_of(ai_provider_available("openai"));
    print ai_mock_chat("Hello");

    print "================================================";
    print " Stdlib S1-S6 Release Contract Complete";
    print "================================================";
}
