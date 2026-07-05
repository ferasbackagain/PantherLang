panther main {
    print "=== Lesson 15: Comparison Semantics ===";
    print "";
    
    print "--- Comparison Policy ---";
    print "PantherLang does NOT perform implicit comparison conversion.";
    print "";
    print "All comparison operators must operate on compatible types:";
    print "  ==, !=, >, <, >=, <=";
    print "";
    
    print "--- Same-Type Comparisons (Allowed) ---";
    print "Numbers:";
    print "  100 == 100    // true";
    print "  100 != 50     // true";
    print "  100 > 50      // true";
    print "  100 < 50      // false";
    print "  100 >= 100    // true";
    print "  50 <= 100     // true";
    print "";
    print "Strings:";
    print "  \"abc\" == \"abc\"   // true";
    print "  \"abc\" != \"xyz\"   // true";
    print "  \"a\" < \"b\"        // true (lexicographic)";
    print "";
    print "Booleans:";
    print "  true == true   // true";
    print "  true != false  // true";
    print "";
    print "Null:";
    print "  null == null   // true";
    print "  null != null   // false";
    print "";
    
    print "--- Different-Type Comparisons (Blocked - PT002) ---";
    print "These produce a PT002 type error:";
    print "  100 == \"100\"      // number vs string";
    print "  100 != \"100\"      // number vs string";
    print "  100 > \"50\"        // number vs string";
    print "  true == 1          // boolean vs number";
    print "  false == 0         // boolean vs number";
    print "  \"true\" == true     // string vs boolean";
    print "";
    
    print "--- Explicit Conversion Required ---";
    print "Use explicit conversion functions:";
    print "  to_int(\"100\") == 100       // true";
    print "  to_string(100) == \"100\"     // true";
    print "  to_bool(1) == true           // true";
    print "";
    
    print "--- Null Comparison Semantics ---";
    print "Null can be compared with any type using == and !=:";
    print "  null == \"hello\"   // false";
    print "  \"hello\" == null   // false";
    print "  null != \"hello\"   // true";
    print "  null == 42        // false";
    print "  null == true      // false";
    print "  null > 5          // PT002 (ordered comparison blocked)";
    print "";
    
    print "--- Rationale ---";
    print "Explicit comparison keeps arithmetic and comparison behavior consistent.";
    print "No hidden type coercion means fewer bugs and predictable code.";
    print "";
    
    print "=== Lesson 15 Complete ===";
}