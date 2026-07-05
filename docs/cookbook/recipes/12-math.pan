panther main {
    print "abs(-5): " + string(abs(-5));
    print "max(10, 20): " + string(max(10, 20));
    print "min(10, 20): " + string(min(10, 20));
    print "pow(2, 10): " + string(pow(2, 10));
    print "sqrt(100): " + string(sqrt(100));
    print "floor(3.9): " + string(floor(3.9));
    print "ceil(3.1): " + string(ceil(3.1));
    print "round(3.5): " + string(round(3.5));

    let r = random();
    print "random: " + string(r);

    let ri = randint(1, 100);
    print "randint 1..100: " + string(ri);

    let now = time();
    print "time: " + string(now);
    sleep(0.1);
    print "slept 0.1s";
}
