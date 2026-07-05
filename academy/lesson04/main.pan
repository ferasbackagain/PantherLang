panther main {
    print "=== Lesson 04: Functions ===";
    print "";
    
    print "--- Basic Function Declaration ---";
    fn greet(msg) {
        return "Greetings: " + msg;
    }
    
    print greet("PantherLang");
    print greet("World");
    print "";
    
    print "--- Parameters and Return Values ---";
    fn add(a, b) {
        return a + b;
    }
    
    fn subtract(a, b) {
        return a - b;
    }
    
    fn no_return() {
        print "This function returns nothing";
    }
    
    fn empty_return() {
        return;
    }
    
    print "add(10, 5) = " + to_string(add(10, 5));
    print "subtract(10, 5) = " + to_string(subtract(10, 5));
    no_return();
    print "empty_return() = " + to_string(empty_return());
    print "";
    
    print "--- Recursion ---";
    fn factorial(n) {
        if n <= 1 {
            return 1;
        }
        return n * factorial(n - 1);
    }
    
    print "factorial(5) = " + to_string(factorial(5));
    print "factorial(0) = " + to_string(factorial(0));
    print "";
    
    print "--- Typed Parameters and Return ---";
    fn add_typed(a: int, b: int): int {
        return a + b;
    }
    
    fn greet_typed(name: string): string {
        return "Hello, " + name + "!";
    }
    
    fn is_even(n: int): bool {
        return n % 2 == 0;
    }
    
    print "add_typed(3, 7) = " + to_string(add_typed(3, 7));
    print "greet_typed(\"Alice\") = " + greet_typed("Alice");
    print "is_even(4) = " + to_string(is_even(4));
    print "is_even(5) = " + to_string(is_even(5));
    print "";
    
    print "--- Closures (Capturing Outer Scope) ---";
    let prefix = "Value: ";
    fn show(x) {
        return prefix + to_string(x);
    }
    
    print show(42);
    print show(100);
    print "";
    
    print "=== Lesson 04 Complete ===";
}