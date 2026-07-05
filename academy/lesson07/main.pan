panther main {
    print "=== Lesson 07: Standard Library ===";
    print "";
    
    print "--- String Functions (11) ---";
    print "len(\"hello\"): " + to_string(len("hello"));
    print "upper(\"hello\"): " + upper("hello");
    print "lower(\"HELLO\"): " + lower("HELLO");
    print "trim(\"  hi  \"): \"" + trim("  hi  ") + "\"";
    print "contains(\"Panther\", \"th\"): " + to_string(contains("Panther", "th"));
    print "starts_with(\"Panther\", \"Pan\"): " + to_string(starts_with("Panther", "Pan"));
    print "ends_with(\"Panther\", \"er\"): " + to_string(ends_with("Panther", "er"));
    print "replace(\"a-b-c\", \"-\", \"/\"): " + replace("a-b-c", "-", "/");
    let parts = split("a,b,c", ",");
    print "split(\"a,b,c\", \",\"): [" + parts[0] + ", " + parts[1] + ", " + parts[2] + "]";
    print "join: " + join(",", ["a", "b"]);
    print "substring(\"Panther\", 2, 5): " + substring("Panther", 2, 5);
    print "";
    
    print "--- Math Functions (10) ---";
    print "abs(-5): " + to_string(abs(-5));
    print "max(10, 20): " + to_string(max(10, 20));
    print "min(10, 20): " + to_string(min(10, 20));
    print "pow(2, 3): " + to_string(pow(2, 3));
    print "sqrt(16): " + to_string(sqrt(16));
    print "floor(3.7): " + to_string(floor(3.7));
    print "ceil(3.2): " + to_string(ceil(3.2));
    print "round(3.5): " + to_string(round(3.5));
    print "random(): " + to_string(random());
    print "randint(1, 10): " + to_string(randint(1, 10));
    print "";
    
    print "--- JSON Functions (2) ---";
    let obj = {name: "Panther", year: 2026};
    let json = json_encode(obj);
    print "json_encode: " + json;
    let decoded = json_decode(json);
    print "json_decode name: " + decoded["name"];
    let arr = json_decode("[10, 20, 30]");
    print "json_decode array[0]: " + to_string(arr[0]);
    print "";
    
    print "--- Time Functions (2) ---";
    let now = time();
    print "time(): " + to_string(now);
    print "sleep(0.1): done";
    sleep(0.1);
    print "";
    
    print "--- Type Conversion (3) ---";
    print "int(\"42\"): " + to_string(int("42"));
    print "float(\"3.14\"): " + to_string(float("3.14"));
    print "string(42): " + string(42);
    print "";
    
    print "--- Crypto / Security (6) ---";
    print "sha256(\"hello\"): " + sha256("hello");
    print "secure_token(16): " + secure_token(16);
    print "sanitize_path: " + sanitize_path("/safe", "/safe/subdir/file.txt");
    print "sanitize_html(\"<script>alert('xss')</script>\"): " + sanitize_html("<script>alert('xss')</script>");
    print "";
    
    print "--- Filesystem Functions (6) ---";
    mkdir("test_dir");
    write_file("test_dir/file.txt", "Hello from PantherLang!");
    let content = read_file("test_dir/file.txt");
    print "read_file: " + content;
    print "file_exists: " + to_string(file_exists("test_dir/file.txt"));
    let files = list_dir("test_dir");
    print "list_dir: [" + files[0] + "]";
    remove_file("test_dir/file.txt");
    print "";
    
    print "--- HTTP Client (2) ---";
    print "http_get/http_post require network (skipped in offline)";
    print "";
    
    print "--- Regex Functions (3) ---";
    print "regex_match: " + to_string(regex_match("[0-9]+", "hello123"));
    print "regex_replace: " + regex_replace("[0-9]", "X", "a1b2");
    let split_result = regex_split(",", "a,b,c");
    print "regex_split: [" + split_result[0] + ", " + split_result[1] + ", " + split_result[2] + "]";
    print "";
    
    print "--- Collections Functions (4) ---";
    let nums = [3, 1, 2];
    array_push(nums, 4);
    print "array_push: " + to_string(nums[3]);
    let popped = array_pop(nums);
    print "array_pop: " + to_string(popped);
    array_sort(nums);
    print "array_sort: " + to_string(nums[0]) + ", " + to_string(nums[1]) + ", " + to_string(nums[2]);
    array_reverse(nums);
    print "array_reverse: " + to_string(nums[0]) + ", " + to_string(nums[1]) + ", " + to_string(nums[2]);
    print "";
    
    print "--- SQLite Functions (4) ---";
    print "db_open/db_execute/db_query/db_close (require DB setup)";
    print "";
    
    print "=== Lesson 07 Complete ===";
}