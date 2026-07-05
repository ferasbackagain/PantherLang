panther main {
    print "=== Lesson 07 Verification ===";
    print "";
    
    print "--- Test 1: String Functions ---";
    if len("hello") == 5 { print "len: PASS"; } else { print "len: FAIL"; }
    if upper("hello") == "HELLO" { print "upper: PASS"; } else { print "upper: FAIL"; }
    if lower("HELLO") == "hello" { print "lower: PASS"; } else { print "lower: FAIL"; }
    if trim("  hi  ") == "hi" { print "trim: PASS"; } else { print "trim: FAIL"; }
    if contains("Panther", "th") == true { print "contains: PASS"; } else { print "contains: FAIL"; }
    if starts_with("Panther", "Pan") == true { print "starts_with: PASS"; } else { print "starts_with: FAIL"; }
    if ends_with("Panther", "er") == true { print "ends_with: PASS"; } else { print "ends_with: FAIL"; }
    if replace("a-b-c", "-", "/") == "a/b/c" { print "replace: PASS"; } else { print "replace: FAIL"; }
    let parts = split("a,b,c", ",");
    if len(parts) == 3 && parts[0] == "a" && parts[1] == "b" && parts[2] == "c" { print "split: PASS"; } else { print "split: FAIL"; }
    if join(",", ["a", "b"]) == "a,b" { print "join: PASS"; } else { print "join: FAIL"; }
    if substring("Panther", 2, 5) == "nth" { print "substring: PASS"; } else { print "substring: FAIL"; }
    
    print "";
    print "--- Test 2: Math Functions ---";
    if abs(-5) == 5 { print "abs: PASS"; } else { print "abs: FAIL"; }
    if max(10, 20) == 20 { print "max: PASS"; } else { print "max: FAIL"; }
    if min(10, 20) == 10 { print "min: PASS"; } else { print "min: FAIL"; }
    if pow(2, 3) == 8 { print "pow: PASS"; } else { print "pow: FAIL"; }
    if sqrt(16) == 4.0 { print "sqrt: PASS"; } else { print "sqrt: FAIL"; }
    if floor(3.7) == 3 { print "floor: PASS"; } else { print "floor: FAIL"; }
    if ceil(3.2) == 4 { print "ceil: PASS"; } else { print "ceil: FAIL"; }
    if round(3.5) == 4 { print "round: PASS"; } else { print "round: FAIL"; }
    // random and randint are non-deterministic
    
    print "";
    print "--- Test 3: JSON Functions ---";
    let obj = {name: "Panther", year: 2026};
    let json = json_encode(obj);
    let decoded = json_decode(json);
    if decoded["name"] == "Panther" && decoded["year"] == 2026 { print "json_encode/decode: PASS"; } else { print "json: FAIL"; }
    let arr = json_decode("[10, 20, 30]");
    if arr[0] == 10 && arr[1] == 20 && arr[2] == 30 { print "json_decode array: PASS"; } else { print "json array: FAIL"; }
    
    print "";
    print "--- Test 4: Time Functions ---";
    let now = time();
    if now > 0 { print "time: PASS"; } else { print "time: FAIL"; }
    sleep(0.05);
    print "sleep: PASS";
    
    print "";
    print "--- Test 5: Type Conversion ---";
    if int("42") == 42 { print "int: PASS"; } else { print "int: FAIL"; }
    if float("3.14") == 3.14 { print "float: PASS"; } else { print "float: FAIL"; }
    if string(42) == "42" { print "string: PASS"; } else { print "string: FAIL"; }
    
    print "";
    print "--- Test 6: Crypto/Security ---";
    if len(sha256("hello")) == 64 { print "sha256: PASS"; } else { print "sha256: FAIL"; }
    if len(secure_token(16)) == 32 { print "secure_token: PASS"; } else { print "secure_token: FAIL"; }
    if sanitize_path("/safe", "/safe/subdir/file.txt") == "/safe/subdir/file.txt" { print "sanitize_path: PASS"; } else { print "sanitize_path: FAIL"; }
    let sanitized = sanitize_html("<script>alert('xss')</script>");
    if sanitized != "<script>alert('xss')</script>" { print "sanitize_html: PASS"; } else { print "sanitize_html: FAIL (got: " + sanitized + ")"; }
    
    print "";
    print "--- Test 7: Filesystem ---";
    mkdir("verify_test_dir");
    write_file("verify_test_dir/file.txt", "test content");
    let content = read_file("verify_test_dir/file.txt");
    if content == "test content" { print "read_file: PASS"; } else { print "read_file: FAIL"; }
    if file_exists("verify_test_dir/file.txt") == true { print "file_exists: PASS"; } else { print "file_exists: FAIL"; }
    let files = list_dir("verify_test_dir");
    if len(files) == 1 && files[0] == "file.txt" { print "list_dir: PASS"; } else { print "list_dir: FAIL"; }
    remove_file("verify_test_dir/file.txt");
    print "remove_file: PASS";
    
    print "";
    print "--- Test 8: Regex ---";
    if regex_match("[0-9]+", "hello123") == true { print "regex_match: PASS"; } else { print "regex_match: FAIL"; }
    if regex_replace("[0-9]", "X", "a1b2") == "aXbX" { print "regex_replace: PASS"; } else { print "regex_replace: FAIL"; }
    let split_result = regex_split(",", "a,b,c");
    if len(split_result) == 3 { print "regex_split: PASS"; } else { print "regex_split: FAIL"; }
    
    print "";
    print "--- Test 9: Collections ---";
    let nums = [3, 1, 2];
    array_push(nums, 4);
    if nums[3] == 4 { print "array_push: PASS"; } else { print "array_push: FAIL"; }
    let popped = array_pop(nums);
    if popped == 4 { print "array_pop: PASS"; } else { print "array_pop: FAIL"; }
    let sorted = array_sort(nums);
    if sorted[0] == 1 && sorted[1] == 2 && sorted[2] == 3 { print "array_sort: PASS"; } else { print "array_sort: FAIL"; }
    let reversed = array_reverse(sorted);
    if reversed[0] == 3 && reversed[1] == 2 && reversed[2] == 1 { print "array_reverse: PASS"; } else { print "array_reverse: FAIL"; }
    
    print "";
    print "=== All Lesson 07 Tests Complete ===";
}