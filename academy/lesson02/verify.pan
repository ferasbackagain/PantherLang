panther main {
    print "=== Lesson 02 Verification ===";
    print "";
    
    print "--- Test 1: Type Inference ---";
    let a = "hello";
    let b = 42;
    let c = 3.14;
    let d = true;
    let e = null;
    
    if type_of(a) == "string" { print "string: PASS"; } else { print "string: FAIL"; }
    if type_of(b) == "int" { print "int: PASS"; } else { print "int: FAIL"; }
    if type_of(c) == "float" { print "float: PASS"; } else { print "float: FAIL"; }
    if type_of(d) == "bool" { print "bool: PASS"; } else { print "bool: FAIL"; }
    if type_of(e) == "null" { print "null: PASS"; } else { print "null: FAIL"; }
    
    print "";
    print "--- Test 2: Type Annotations ---";
    let f: int = 100;
    let g: string = "test";
    let h: float = 1.5;
    let i: bool = false;
    let j: any = null;
    
    if type_of(f) == "int" { print "int annotation: PASS"; } else { print "int annotation: FAIL"; }
    if type_of(g) == "string" { print "string annotation: PASS"; } else { print "string annotation: FAIL"; }
    if type_of(h) == "float" { print "float annotation: PASS"; } else { print "float annotation: FAIL"; }
    if type_of(i) == "bool" { print "bool annotation: PASS"; } else { print "bool annotation: FAIL"; }
    if type_of(j) == "null" { print "any annotation: PASS"; } else { print "any annotation: FAIL"; }
    
    print "";
    print "--- Test 3: Reassignment ---";
    let k = 1;
    k = 2;
    if k == 2 { print "Reassignment: PASS"; } else { print "Reassignment: FAIL"; }
    
    print "";
    print "--- Test 4: Compound Assignment ---";
    let m = 10;
    m += 5;
    if m == 15 { print "+=: PASS"; } else { print "+=: FAIL"; }
    m -= 3;
    if m == 12 { print "-=: PASS"; } else { print "-=: FAIL"; }
    m *= 2;
    if m == 24 { print "*=: PASS"; } else { print "*=: FAIL"; }
    m /= 4;
    if m == 6 { print "/=: PASS"; } else { print "/=: FAIL"; }
    m %= 4;
    if m == 2 { print "%=: PASS"; } else { print "%=: FAIL"; }
    
    print "";
    print "--- Test 5: Scope ---";
    let outer = "global";
    {
        let inner = "local";
        if outer == "global" { print "outer in block: PASS"; } else { print "outer in block: FAIL"; }
        if inner == "local" { print "inner in block: PASS"; } else { print "inner in block: FAIL"; }
    }
    if outer == "global" { print "outer after block: PASS"; } else { print "outer after block: FAIL"; }
    
    print "";
    print "=== All Lesson 02 Tests Complete ===";
}