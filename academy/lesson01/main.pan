panther main {
    print "=== Lesson 01: Expressions & Operators ===";
    
    // Arithmetic
    print 10 + 5 * 2;      // 20 (precedence)
    print (10 + 5) * 2;    // 30
    print 2 ** 10;         // 1024
    
    // Comparison
    print 10 > 5;          // true
    print 10 == 10;        // true
    print "a" < "b";       // true
    
    // Logical
    print true && false;   // false
    print true || false;   // true
    print !true;           // false
    
    // String concat
    print "Hello " + "World";
}
