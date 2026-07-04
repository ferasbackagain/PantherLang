from compiler.runtime import execute_source


def run(src: str):
    result = execute_source(src)
    assert result.error is None, result.error
    return result.captured_output


def test_s1_types_and_conversion():
    out = run('''
panther main {
    print type_of(45);
    print type_of("x");
    print to_string(45) + " Feras";
    print to_int("50") + 5;
    print to_number("60") + 10;
    print to_bool("true");
}
''')
    assert out == ["int", "string", "45 Feras", "55", "70.0", "true"]


def test_s2_filesystem(tmp_path):
    path = tmp_path / "panther.txt"
    out = run(f'''
panther main {{
    print fs_write("{path}", "hello");
    print fs_exists("{path}");
    print fs_read("{path}");
    print fs_absolute("{path}");
}}
''')
    assert out[0:3] == ["true", "true", "hello"]
    assert str(path) in out[3]


def test_s3_system_smoke():
    out = run('''
panther main {
    print type_of(system_os());
    print type_of(system_arch());
    print type_of(system_cpu_count());
    print type_of(system_disk("."));
}
''')
    assert out == ["string", "string", "int", "object"]


def test_s4_json_net_smoke():
    out = run(r'''
panther main {
    let obj = json_parse("{\"name\": \"Panther\", \"ok\": true}");
    print obj["name"];
    print json_valid("{\"ok\": true}");
    print type_of(net_interfaces());
    print type_of(net_local_ip());
}
''')
    assert out[0] == "Panther"
    assert out[1] == "true"
    assert out[2] == "array"
    assert out[3] == "string"


def test_s5_crypto():
    out = run('''
panther main {
    print len(crypto_sha256("panther"));
    print type_of(crypto_uuid());
    print crypto_base64_decode(crypto_base64_encode("PantherLang"));
    print crypto_hex_decode(crypto_hex_encode("Panther"));
}
''')
    assert out == ["64", "string", "PantherLang", "Panther"]


def test_s6_ai_safe_helpers():
    out = run('''
panther main {
    print type_of(ai_supported_providers());
    print type_of(ai_provider_available("openai"));
    print ai_mock_chat("hello");
}
''')
    assert out[0] == "array"
    assert out[1] == "bool"
    assert "hello" in out[2]
