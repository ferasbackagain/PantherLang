panther main {
    print "=== Lesson 02: Variables & Types ===";
    print "";
    
    print "--- Type Inference ---";
    let name = "PantherLang";
    let year = 2026;
    let pi = 3.14;
    let is_ready = true;
    let data = null;
    
    print "name: " + name + " (type: " + type_of(name) + ")";
    print "year: " + to_string(year) + " (type: " + type_of(year) + ")";
    print "pi: " + to_string(pi) + " (type: " + type_of(pi) + ")";
    print "is_ready: " + to_string(is_ready) + " (type: " + type_of(is_ready) + ")";
    print "data: " + to_string(data) + " (type: " + type_of(data) + ")";
    print "";
    
    print "--- Explicit Type Annotations ---";
    let count: int = 42;
    let label: string = "total";
    let ratio: float = 0.5;
    let flag: bool = false;
    let result: any = null;
    
    print "count: " + to_string(count) + " (annotated int)";
    print "label: " + label + " (annotated string)";
    print "ratio: " + to_string(ratio) + " (annotated float)";
    print "flag: " + to_string(flag) + " (annotated bool)";
    print "result: " + to_string(result) + " (annotated any)";
    print "";
    
    print "--- Reassignment ---";
    let x = 10;
    print "x initially: " + to_string(x);
    x = 20;
    print "x after reassignment: " + to_string(x);
    print "";
    
    print "--- Compound Assignment ---";
    let y = 10;
    print "y initially: " + to_string(y);
    y += 5;
    print "y += 5: " + to_string(y);
    y -= 3;
    print "y -= 3: " + to_string(y);
    y *= 2;
    print "y *= 2: " + to_string(y);
    y /= 4;
    print "y /= 4: " + to_string(y);
    y %= 3;
    print "y %= 3: " + to_string(y);
    print "";
    
    print "--- Variable Scope ---";
    let outer = "global";
    {
        let inner = "local";
        print "outer in block: " + outer;
        print "inner in block: " + inner;
    }
    print "outer after block: " + outer;
    print "inner after block: ERROR (out of scope)";
    print "";
    
    print "=== Lesson 02 Complete ===";
}