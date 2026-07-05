panther main {
    print "=== Lab 17: Advanced Data Processing Solutions ===";
    print "";

    print "Exercise 1: Read JSON data and extract insights";
    print "";

    let json_data = "{\"products\": [{\"name\": \"Widget\", \"price\": 9.99, \"stock\": 42}, {\"name\": \"Gadget\", \"price\": 24.99, \"stock\": 15}, {\"name\": \"Doohickey\", \"price\": 4.99, \"stock\": 100}]}";

    let parsed = json_decode(json_data);
    let products = parsed["products"];
    print "  Products found: " + string(len(products));

    let i = 0;
    while i < len(products) {
        let p = products[i];
        print "    " + p["name"] + " - $" + string(p["price"]) + " (" + string(p["stock"]) + " in stock)";
        i = i + 1;
    }
    print "";

    print "Exercise 2: Process CSV-like data with split and join";
    print "";

    let csv_data = "title,author,year\nPantherLang Guide,Alice,2025\nAdvanced Topics,Bob,2026\nBest Practices,Charlie,2025";
    let lines = split(csv_data, "\n");
    print "  CSV has " + string(len(lines)) + " lines (including header)";

    let j = 1;
    while j < len(lines) {
        let cols = split(lines[j], ",");
        if len(cols) >= 3 {
            let record = join(" | ", cols);
            print "    Row " + string(j) + ": " + record;
        }
        j = j + 1;
    }
    print "";

    print "Exercise 3: Data pipeline - read, transform, write";
    print "";

    let raw_data = "zeta,alpha,delta,beta,gamma,epsilon";
    print "  Raw: " + raw_data;

    let items = split(raw_data, ",");
    let sorted_items = array_sort(items);
    let sorted_str = join(", ", sorted_items);
    print "  Sorted: " + sorted_str;

    let reversed_items = array_reverse(sorted_items);
    let reversed_str = join(", ", reversed_items);
    print "  Reversed: " + reversed_str;

    let final_output = join("\n", reversed_items);
    print "  Written (one per line):";
    print final_output;
    print "";

    print "=== Lab 17 Complete ===";
}
