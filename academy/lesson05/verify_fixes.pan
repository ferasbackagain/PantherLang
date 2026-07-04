panther main {

    print "================================================";
    print " Panther Academy Lessons 01-05 Verification";
    print "================================================";

    print "";
    print "1) TYPES";
    print "------------------------------------------------";

    let age = 45;
    let name = "Feras";
    let active = true;

    print type_of(age);
    print type_of(name);
    print type_of(active);

    print "";
    print "2) EXPLICIT CONVERSIONS";
    print "------------------------------------------------";

    let number_text = "50";

    print to_string(age);
    print to_int(number_text) + 5;
    print to_number(number_text) + 10;
    print to_bool(active);

    print "";
    print "3) NO IMPLICIT CONVERSION POLICY";
    print "------------------------------------------------";
    print "PantherLang blocks this:";
    print "age + name";
    print "Use explicit conversion instead:";
    print to_string(age) + " " + name;

    print "";
    print "4) ARITHMETIC";
    print "------------------------------------------------";

    let a = 10;
    let b = 5;

    print a + b;
    print a - b;
    print a * b;
    print a / b;
    print a % b;
    print a ** 2;

    print "";
    print "5) STRINGS";
    print "------------------------------------------------";

    let first = "Panther";
    let second = "Lang";

    print first + second;
    print first + " " + second;

    print "";
    print "6) BOOLEAN";
    print "------------------------------------------------";

    let passed = true;
    let failed = false;

    print passed;
    print failed;

    print "";
    print "7) ARRAYS";
    print "------------------------------------------------";

    let nums = [10, 20, 30];

    print nums[0];
    print nums[1];
    print nums[2];

    print "";
    print "8) OBJECTS";
    print "------------------------------------------------";

    let user = {
        name: "Feras",
        role: "Founder",
        language: "PantherLang"
    };

    print user["name"];
    print user["role"];
    print user["language"];

    print "";
    print "9) RUNTIME ERROR POLICY";
    print "------------------------------------------------";
    print "Division by zero should produce PR001 if tested separately.";
    print "Type mismatch should produce PT001 if tested separately.";

    print "";
    print "================================================";
    print " Lessons 01-05 PantherLang Verification Complete";
    print "================================================";
}
