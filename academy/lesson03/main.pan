panther main {
    print "=== Lesson 03: Control Flow ===";
    print "";
    
    print "--- If / Elif / Else ---";
    let score = 85;
    
    if score >= 90 {
        print "Grade: A";
    } elif score >= 80 {
        print "Grade: B";
    } elif score >= 70 {
        print "Grade: C";
    } elif score >= 60 {
        print "Grade: D";
    } else {
        print "Grade: F";
    }
    print "";
    
    print "--- While Loop ---";
    let i = 0;
    while i < 5 {
        print "i = " + to_string(i);
        i = i + 1;
    }
    print "";
    
    print "--- For Range Loop ---";
    for n in 0..5 {
        print "n = " + to_string(n);
    }
    print "";
    
    print "--- Infinite Loop with Break ---";
    let count = 0;
    loop {
        print "count = " + to_string(count);
        count = count + 1;
        if count >= 3 {
            break;
        }
    }
    print "";
    
    print "--- Break and Continue ---";
    let j = 0;
    while j < 10 {
        j = j + 1;
        if j == 3 {
            continue;
        }
        if j == 7 {
            break;
        }
        print "j = " + to_string(j);
    }
    print "";
    
    print "=== Lesson 03 Complete ===";
}