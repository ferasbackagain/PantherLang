panther main {
    print("=== PantherLang Data Pipeline ===");
    print("");

    // Step 1: Generate structured data
    print("[1] Generate dataset");
    let names = ["Alice", "Bob", "Charlie", "Diana"];
    let scores = [95, 87, 92, 78];
    let csv_rows = [["name", "score", "grade"]];
    for i in 0..len(names)-1 {
        let grade = "A";
        if scores[i] < 80 {
            grade = "B";
        };
        array_push(csv_rows, [names[i], to_string(scores[i]), grade]);
    };
    print("Template: " + csv_rows[0][0] + ", " + csv_rows[0][1] + ", " + csv_rows[0][2]);
    print("");

    // Step 2: Convert to CSV
    print("[2] Serialize to CSV");
    let csv_text = csv_stringify(csv_rows);
    print(csv_text);
    print("");

    // Step 3: Parse CSV
    print("[3] Parse CSV back to objects");
    let parsed = csv_parse_objects(csv_text);
    for i in 0..len(parsed)-1 {
        let row = parsed[i];
        let now = datetime_now();
        print("  " + row["name"] + " scored " + row["score"] + " -> " + row["grade"]);
    };
    print("");

    // Step 4: URL encode data
    print("[4] URL encode/decode");
    let raw = "name=PantherLang&version=1.1.6";
    let encoded = url_encode(raw);
    let decoded = url_decode(encoded);
    print("Raw:    " + raw);
    print("Encoded: " + encoded);
    print("Decoded: " + decoded);
    print("");

    // Step 5: Timestamps
    print("[5] Timestamp processing");
    let now_ts = time();
    let readable = datetime_format(now_ts, "%Y-%m-%d %H:%M:%S");
    print("Current: " + readable);
    let parsed_ts = datetime_parse("2026-01-15T10:30:00");
    let parsed_readable = datetime_format(parsed_ts, "%B %d, %Y at %H:%M");
    print("Parsed:  " + parsed_readable);
    print("");

    print("=== Data Pipeline Complete ===");
}
