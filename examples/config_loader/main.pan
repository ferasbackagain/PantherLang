panther main {
    print "=== PantherLang Configuration Loader ===";

    let config_json = "{\n
    \"app_name\": \"PantherDemo\",\n
    \"version\": \"1.0.0\",\n
    \"debug\": true,\n
    \"database\": {\n
        \"host\": \"localhost\",\n
        \"port\": 5432,\n
        \"name\": \"panther_db\"\n
    },\n
    \"features\": [\"auth\", \"logging\", \"analytics\"]\n
}";

    write_file("config.json", config_json);
    print "Config file written";

    let raw = read_file("config.json");
    let config = json_decode(raw);

    print "App: " + config["app_name"] + " v" + config["version"];
    print "Debug mode: " + string(config["debug"]);

    let db = config["database"];
    print "Database: " + db["host"] + ":" + string(db["port"]) + "/" + db["name"];

    let features = config["features"];
    print "Features (" + string(len(features)) + "):";
    let i = 0;
    while i < len(features) {
        print "  - " + features[i];
        i = i + 1;
    }

    remove_file("config.json");
    print "=== Configuration Loader Demo Complete ===";
}
