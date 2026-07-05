from pathlib import Path

from compiler.runtime import execute_source


def run(source: str):
    result = execute_source(source)
    assert result.error is None, result.error
    return result.captured_output


def test_s1_types_and_explicit_conversion_contract():
    out = run(r'''
panther main {
    print type_of(45);
    print type_of("Panther");
    print type_of(true);
    print to_string(45) + " Panther";
    print to_int("50") + 5;
    print to_number("60") + 10;
    print to_bool("true");
}
''')
    assert out[:7] == ["int", "string", "bool", "45 Panther", "55", "70.0", "true"]


def test_s2_filesystem_contract():
    out = run(r'''
panther main {
    print fs_mkdir(".panther_tmp/contract_test");
    print fs_write(".panther_tmp/contract_test/a.txt", "hello");
    print fs_append(".panther_tmp/contract_test/a.txt", " world");
    print fs_exists(".panther_tmp/contract_test/a.txt");
    print fs_read(".panther_tmp/contract_test/a.txt");
    print type_of(fs_listdir(".panther_tmp/contract_test"));
    print type_of(fs_cwd());
    print type_of(fs_absolute(".panther_tmp/contract_test/a.txt"));
}
''')
    assert "hello world" in out
    assert out[-3:] == ["array", "string", "string"]


def test_s3_system_time_random_contract():
    out = run(r'''
panther main {
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
}
''')
    assert out == ["string", "string", "string", "string", "int", "string", "object", "string", "int", "float", "float", "int"]


def test_s4_network_json_sqlite_contract():
    out = run(r'''
panther main {
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
    let conn = sqlite_open(".panther_tmp/contract_test/s4.db");
    print type_of(conn);
    print sqlite_execute(conn, "CREATE TABLE IF NOT EXISTS items (name TEXT)");
    print sqlite_execute(conn, "DELETE FROM items");
    print sqlite_execute(conn, "INSERT INTO items (name) VALUES ('Panther')");
    print type_of(sqlite_query(conn, "SELECT name FROM items"));
    print sqlite_close(conn);
}
''')
    assert out[0:8] == ["string", "string", "array", "array", "string", "string", "bool", "array"]
    assert "Panther" in out
    assert "true" in out
    assert "object" in out
    assert "array" in out


def test_s5_crypto_contract():
    out = run(r'''
panther main {
    print type_of(crypto_sha256("Panther"));
    print type_of(crypto_sha512("Panther"));
    print type_of(crypto_md5("Panther"));
    print type_of(crypto_hmac_sha256("key", "message"));
    print type_of(crypto_uuid());
    print type_of(crypto_random_bytes(8));
    print type_of(crypto_secure_random_int(1, 10));
    print crypto_base64_decode(crypto_base64_encode("Panther"));
    print crypto_hex_decode(crypto_hex_encode("Panther"));
}
''')
    assert out[:6] == ["string"] * 6
    assert out[6] == "int"
    assert out[-2:] == ["Panther", "Panther"]


def test_s6_ai_contract():
    out = run(r'''
panther main {
    print type_of(ai_supported_providers());
    print type_of(ai_provider_available("openai"));
    print ai_mock_chat("Hello");
}
''')
    assert out[0] == "array"
    assert out[1] == "bool"
    assert "PantherAI mock response" in out[2]


def test_s6_ai_chat_contract():
    out = run(r'''
panther main {
    print type_of(ai_chat("Hello Panther"));
    print type_of(ai_available_providers());
    print ai_chat("Hello", "mock");
}
''')
    assert out[0] == "string"
    assert out[1] == "array"
    assert "PantherAI" in out[2]


def test_contract_docs_and_scripts_exist():
    required = [
        "docs/stdlib/STDLIB_S1_S6_API_CONTRACT.md",
        "examples/stdlib_s1_s6_contract/main.pan",
        "scripts/run_stdlib_s1_s6_contract.sh",
        "scripts/run_stdlib_s1_s6_contract.ps1",
        "scripts/run_stdlib_s1_s6_contract.bat",
    ]
    for rel in required:
        assert Path(rel).exists(), rel
