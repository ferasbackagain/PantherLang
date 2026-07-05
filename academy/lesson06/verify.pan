panther main {
    print "=== Lesson 06 Verification ===";
    print "";
    
    print "--- Test 1: Arrays ---";
    let numbers = [10, 20, 30];
    if len(numbers) == 3 { print "Array len: PASS"; } else { print "Array len: FAIL"; }
    if numbers[0] == 10 { print "Array index: PASS"; } else { print "Array index: FAIL"; }
    if numbers[2] == 30 { print "Array last: PASS"; } else { print "Array last: FAIL"; }
    
    print "";
    print "--- Test 2: Array Iteration ---";
    let sum = 0;
    for i in 0..len(numbers) {
        sum = sum + numbers[i];
    }
    if sum == 60 { print "Array sum: PASS"; } else { print "Array sum: FAIL (got " + to_string(sum) + ")"; }
    
    print "";
    print "--- Test 3: Array Methods ---";
    let fruits = ["apple", "banana"];
    array_push(fruits, "cherry");
    if len(fruits) == 3 { print "array_push: PASS"; } else { print "array_push: FAIL"; }
    if fruits[2] == "cherry" { print "push value: PASS"; } else { print "push value: FAIL"; }
    let popped = array_pop(fruits);
    if popped == "cherry" { print "array_pop value: PASS"; } else { print "array_pop value: FAIL"; }
    if len(fruits) == 2 { print "array_pop len: PASS"; } else { print "array_pop len: FAIL"; }
    
    print "";
    print "--- Test 4: Array Sort/Reverse ---";
    let unsorted = [3, 1, 2];
    let sorted = array_sort(unsorted);
    if sorted[0] == 1 && sorted[1] == 2 && sorted[2] == 3 { print "array_sort: PASS"; } else { print "array_sort: FAIL"; }
    let reversed = array_reverse(sorted);
    if reversed[0] == 3 && reversed[1] == 2 && reversed[2] == 1 { print "array_reverse: PASS"; } else { print "array_reverse: FAIL"; }
    
    print "";
    print "--- Test 5: Objects ---";
    let person = {name: "Alice", age: 30};
    if person["name"] == "Alice" { print "Object access: PASS"; } else { print "Object access: FAIL"; }
    if person["age"] == 30 { print "Object int value: PASS"; } else { print "Object int value: FAIL"; }
    
    print "";
    print "--- Test 6: Nested Objects ---";
    let config = {db: {host: "localhost"}};
    if config["db"]["host"] == "localhost" { print "Nested object: PASS"; } else { print "Nested object: FAIL"; }
    
    print "";
    print "--- Test 7: Structs ---";
    struct Point { x y }
    let p = Point(10, 20);
    if p.x == 10 && p.y == 20 { print "Struct: PASS"; } else { print "Struct: FAIL"; }
    
    print "";
    print "--- Test 8: Mixed Collections ---";
    let data = {nums: [1, 2], user: {name: "test"}};
    if data["nums"][0] == 1 { print "Mixed array access: PASS"; } else { print "Mixed array access: FAIL"; }
    if data["user"]["name"] == "test" { print "Mixed object access: PASS"; } else { print "Mixed object access: FAIL"; }
    
    print "";
    print "=== All Lesson 06 Tests Complete ===";
}