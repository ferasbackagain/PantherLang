panther main {
    print "=== Lesson 04 Verification ===";
    print "";
    
    print "--- Test 1: Basic Function ---";
    fn greet(msg) {
        return "Greetings: " + msg;
    }
    if greet("Test") == "Greetings: Test" { print "Basic Function: PASS"; } else { print "Basic Function: FAIL"; }
    
    print "";
    print "--- Test 2: Parameters and Return ---";
    fn add(a, b) {
        return a + b;
    }
    fn subtract(a, b) {
        return a - b;
    }
    if add(10, 5) == 15 { print "Add: PASS"; } else { print "Add: FAIL"; }
    if subtract(10, 5) == 5 { print "Subtract: PASS"; } else { print "Subtract: FAIL"; }
    
    fn empty_return() {
        return;
    }
    if empty_return() == null { print "Empty Return: PASS"; } else { print "Empty Return: FAIL"; }
    
    print "";
    print "--- Test 3: Recursion ---";
    fn factorial(n) {
        if n <= 1 {
            return 1;
        }
        return n * factorial(n - 1);
    }
    if factorial(5) == 120 { print "Factorial 5: PASS"; } else { print "Factorial 5: FAIL"; }
    if factorial(0) == 1 { print "Factorial 0: PASS"; } else { print "Factorial 0: FAIL"; }
    
    print "";
    print "--- Test 4: Typed Parameters ---";
    fn add_typed(a: int, b: int): int {
        return a + b;
    }
    fn greet_typed(name: string): string {
        return "Hello, " + name + "!";
    }
    fn is_even(n: int): bool {
        return n % 2 == 0;
    }
    if add_typed(3, 7) == 10 { print "Typed Add: PASS"; } else { print "Typed Add: FAIL"; }
    if greet_typed("Alice") == "Hello, Alice!" { print "Typed Greet: PASS"; } else { print "Typed Greet: FAIL"; }
    if is_even(4) == true { print "Typed Even 4: PASS"; } else { print "Typed Even 4: FAIL"; }
    if is_even(5) == false { print "Typed Even 5: PASS"; } else { print "Typed Even 5: FAIL"; }
    
    print "";
    print "--- Test 5: Closures ---";
    let prefix = "Value: ";
    fn show(x) {
        return prefix + to_string(x);
    }
    if show(42) == "Value: 42" { print "Closure: PASS"; } else { print "Closure: FAIL"; }
    if show(100) == "Value: 100" { print "Closure 2: PASS"; } else { print "Closure 2: FAIL"; }
    
    print "";
    print "=== All Lesson 04 Tests Complete ===";
}