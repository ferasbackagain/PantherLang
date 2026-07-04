panther main {
    print "================================================";
    print " PantherLang Standard Library S1-S6 Demo";
    print "================================================";

    print "S1 TYPES + IO";
    print type_of(45);
    print to_string(45) + " Feras";
    print to_int("50") + 5;
    print to_number("60") + 10;
    print to_bool("true");
    print println("Panther", "Stdlib", "Ready");
    print printf("Hello {}", "Panther");

    print "S2 FILESYSTEM";
    print fs_write(".panther_tmp/stdlib_s1_s6.txt", "Panther FS OK");
    print fs_exists(".panther_tmp/stdlib_s1_s6.txt");
    print fs_read(".panther_tmp/stdlib_s1_s6.txt");
    print fs_absolute(".panther_tmp/stdlib_s1_s6.txt");

    print "S3 SYSTEM";
    print system_os();
    print system_arch();
    print system_hostname();
    print system_cpu_count();

    print "S4 NET HTTP JSON SQLITE";
    print net_local_ip();
    print net_gateway();
    print net_interfaces();
    let obj = json_parse("{\"name\": \"Panther\", \"version\": 1}");
    print obj["name"];
    print json_valid("{\"ok\": true}");

    print "S5 CRYPTO";
    print crypto_sha256("panther");
    print crypto_uuid();
    print crypto_base64_encode("PantherLang");
    print crypto_base64_decode("UGFudGhlckxhbmc=");

    print "S6 AI";
    print ai_supported_providers();
    print ai_provider_available("openai");
    print ai_mock_chat("Hello from PantherLang");

    print "================================================";
    print " Stdlib S1-S6 Demo Complete";
    print "================================================";
}
