panther main {
    let user = {
        name: "Alice",
        age: 30,
        email: "alice@example.com",
        scores: [85, 90, 92]
    };
    print "name: " + user["name"];
    print "age: " + string(user["age"]);
    print "email: " + user["email"];
    print "first score: " + string(user["scores"][0]);

    // JSON round-trip
    let json = json_encode(user);
    print "JSON: " + json;
    let decoded = json_decode(json);
    print "decoded name: " + decoded["name"];
}
