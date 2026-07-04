panther main {
    print "=== PantherLang JSON Parser ===";

    let data = json_encode({name: "Panther", version: "1.0.0", year: 2026});
    print "Encoded JSON: " + data;

    let parsed = json_decode(data);
    print "Decoded name: " + parsed["name"];
    print "Decoded version: " + parsed["version"];
    print "Decoded year: " + string(parsed["year"]);

    let arr = json_decode("[10, 20, 30]");
    print "Array length: " + string(len(arr));
    print "First element: " + string(arr[0]);
    print "Last element: " + string(arr[2]);

    let nested = json_decode("{\"user\": {\"name\": \"Alice\", \"scores\": [95, 87, 92]}}");
    print "Nested user name: " + nested["user"]["name"];
    print "Scores count: " + string(len(nested["user"]["scores"]));

    print "=== JSON Parser Demo Complete ===";
}
