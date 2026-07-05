panther main {
    let data = {
        title: "PantherLang",
        version: 1.1,
        features: ["fast", "secure", "simple"],
        active: true
    };
    let encoded = json_encode(data);
    print "encoded: " + encoded;
    let decoded = json_decode(encoded);
    print "title: " + decoded["title"];
    print "version: " + string(decoded["version"]);
    print "feature 0: " + decoded["features"][0];

    // Array JSON
    let arr = json_decode("[100, 200, 300]");
    print "arr sum: " + string(arr[0] + arr[1] + arr[2]);
}
