panther main {
    print len("Panther");
    print upper("hello");
    print lower("WORLD");
    print trim("  hi  ");
    print contains("Panther", "th");
    print replace("a-b-c", "-", "/");
    print abs(-5);
    print max(10, 20);
    print sqrt(16);
    print string(42);
    print int("42");
    print float("3.14");
    let data = json_encode({name: "Panther", year: 2026});
    print data;
}
