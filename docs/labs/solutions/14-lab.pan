panther main {
    print "=== Lab 14: Language Reference Solutions ===";
    print "";

    print "Exercise 1: E003 - Duplicate function definition";
    print "  Trigger: Define two functions with the same name";
    print "  Fix: Use unique names or remove the duplicate";
    print "";

    fn add(x, y) {
        return x + y;
    }
    print "  Function 'add' defined once: " + string(add(3, 4));
    print "  A second 'fn add' would trigger E003 at parse time";
    print "";

    print "Exercise 2: T001 - Type mismatch";
    print "  Trigger: Assign value of wrong type to annotated variable";
    print "  Example: 'let x: string = 42' triggers T001";
    print "  Fix: Use correct type or convert explicitly";
    print "";

    let name: string = "Panther";
    print "  Correct: let name: string = \"Panther\" -> " + name;
    print "  Incorrect: let name: string = 42  -> T001 (expected string, got int)";
    print "";

    let count: int = 10;
    let count_str: string = string(count);
    print "  Fix with conversion: string(count) -> " + count_str;
    print "";

    print "Exercise 3: E008 - Undefined variable";
    print "  Trigger: Reference a variable that was never declared";
    print "  Example: 'print z' when z is not defined";
    print "  Fix: Declare the variable before using it";
    print "";

    let z = 100;
    print "  Declared z = " + string(z);
    print "  Before fix: 'print z' would trigger E008 (z undefined)";
    print "  After fix: declare 'let z = 100' first, then reference it";
    print "";

    print "=== Lab 14 Complete ===";
}
