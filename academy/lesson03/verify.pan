panther main {
    print "=== Lesson 03 Verification ===";
    print "";
    
    print "--- Test 1: If/Elif/Else ---";
    let score = 85;
    let grade = "";
    if score >= 90 {
        grade = "A";
    } elif score >= 80 {
        grade = "B";
    } elif score >= 70 {
        grade = "C";
    } elif score >= 60 {
        grade = "D";
    } else {
        grade = "F";
    }
    if grade == "B" { print "If/Elif/Else: PASS"; } else { print "If/Elif/Else: FAIL (got " + grade + ")"; }
    
    print "";
    print "--- Test 2: While Loop ---";
    let i = 0;
    let sum = 0;
    while i < 5 {
        sum = sum + i;
        i = i + 1;
    }
    if sum == 10 { print "While Loop: PASS"; } else { print "While Loop: FAIL (got " + to_string(sum) + ")"; }
    
    print "";
    print "--- Test 3: For Range Loop ---";
    let total = 0;
    for n in 0..5 {
        total = total + n;
    }
    if total == 15 { print "For Loop (0..5): PASS - sum is 15"; } else { print "For Loop: FAIL (got " + to_string(total) + ")"; }
    
    print "";
    print "--- Test 4: Loop with Break ---";
    let count = 0;
    loop {
        count = count + 1;
        if count >= 3 {
            break;
        }
    }
    if count == 3 { print "Loop with Break: PASS"; } else { print "Loop with Break: FAIL (got " + to_string(count) + ")"; }
    
    print "";
    print "--- Test 5: Continue ---";
    let odds = 0;
    for i in 1..6 {
        if i % 2 == 0 {
            continue;
        }
        odds = odds + 1;
    }
    if odds == 3 { print "Continue: PASS"; } else { print "Continue: FAIL (got " + to_string(odds) + ")"; }
    
    print "";
    print "--- Test 6: Nested Loops ---";
    let matrix = [[1, 2], [3, 4], [5, 6]];
    let elements = 0;
    for row in 0..(len(matrix) - 1) {
        for col in 0..(len(matrix[row]) - 1) {
            elements = elements + 1;
        }
    }
    if elements == 6 { print "Nested Loops: PASS"; } else { print "Nested Loops: FAIL (got " + to_string(elements) + ")"; }
    
    print "";
    print "=== All Lesson 03 Tests Complete ===";
}