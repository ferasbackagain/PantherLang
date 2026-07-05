panther main {
    let a = int("42");
    let b = float("3.14");
    let c = "hello";
    print a;
    print type_of(a);
    print b;
    print type_of(b);
    print c;
    print type_of(c);

    let temp_str = "98.6";
    let f = float(temp_str);
    let celsius = (f - 32) * 5 / 9;
    print string(celsius) + "C";

    print float("12.5");
    print int("42");
    print string(null);
    print string(true);
    print type_of("42");
    print type_of(42);
}
