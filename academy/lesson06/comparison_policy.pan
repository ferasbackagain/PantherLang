panther main {
    print "================================================";
    print " Panther Academy Lesson 06 - Comparisons";
    print "================================================";

    print "Number comparisons";
    print 100 == 100;
    print 100 != 50;
    print 100 > 50;
    print 100 < 50;
    print 100 >= 100;
    print 50 <= 100;

    print "String comparisons";
    print "Feras" == "Feras";
    print "Feras" != "Manal";

    print "Boolean comparisons";
    print true == true;
    print true != false;

    print "Policy";
    print "Different-type comparisons must use explicit conversion.";
    print "Example: to_int(\"100\") == 100";
    print to_int("100") == 100;

    print "================================================";
    print " Comparison policy verified";
    print "================================================";
}
