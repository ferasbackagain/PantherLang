panther main {
    for i in 1..15 {
        if i % 3 == 0 && i % 5 == 0 {
            print "FizzBuzz";
        } elif i % 3 == 0 {
            print "Fizz";
        } elif i % 5 == 0 {
            print "Buzz";
        } else {
            print i;
        }
    }

    let i = 1;
    let sum = 0;
    while i <= 100 {
        sum = sum + i;
        i = i + 1;
    }
    print sum;

    let j = 1;
    let found = 0;
    loop {
        if j > 200 {
            break;
        }
        if j % 7 == 0 && j % 13 == 0 {
            found = j;
            break;
        }
        j = j + 1;
    }
    print found;
}
