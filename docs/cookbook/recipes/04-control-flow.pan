panther main {
    // if/elif/else
    let x = 42;
    if x > 100 {
        print "x > 100";
    } elif x > 10 {
        print "x > 10 (PASS)";
    } else {
        print "x <= 10";
    }

    // for range
    let sum = 0;
    for i in 0..4 {
        sum = sum + i;
    }
    print "sum 0..4 = " + string(sum);

    // while
    let count = 0;
    while count < 3 {
        count = count + 1;
    }
    print "count = " + string(count);

    // loop with break
    let n = 0;
    loop {
        n = n + 1;
        if n >= 3 {
            break;
        }
    }
    print "loop n = " + string(n);

    // continue
    let evens = 0;
    for i in 0..5 {
        if i % 2 != 0 {
            continue;
        }
        evens = evens + i;
    }
    print "sum evens 0..5 = " + string(evens);
}
