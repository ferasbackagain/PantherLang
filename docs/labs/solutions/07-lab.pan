panther main {
    print "=== Lab 07: Standard Library ===";

    print "--- Exercise 1: String Analysis ---";
    let text = "PantherLang is a modern programming language";
    let words = split(text, " ");
    print "Word count: " + string(len(words));
    print "Starts with 'Panther': " + string(starts_with(text, "Panther"));
    print "Ends with 'language': " + string(ends_with(text, "language"));
    print "Contains 'modern': " + string(contains(text, "modern"));
    let sub = substring(text, 0, 10);
    print "First 10 chars: '" + sub + "'";

    print "--- Exercise 2: Statistics ---";
    let scores = [85, 90, 78, 92, 88];
    let sum = 0;
    for i in 0..4 {
        sum = sum + scores[i];
    }
    let mean = sum / 5;
    print "Sum: " + string(sum);
    print "Mean: " + string(mean);
    let sorted = array_sort(scores);
    let median = sorted[2];
    print "Median: " + string(median);

    print "--- Exercise 3: JSON ---";
    let profile = {name: "Alice", age: 30, city: "New York"};
    let json = json_encode(profile);
    print "Encoded: " + json;
    let decoded = json_decode(json);
    print "Decoded name: " + decoded["name"];
    print "Decoded age: " + string(decoded["age"]);
    print "Decoded city: " + decoded["city"];
}
