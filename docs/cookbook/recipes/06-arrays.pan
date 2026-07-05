panther main {
    let fruits = ["apple", "banana", "cherry"];
    print "fruits[0] = " + fruits[0];
    print "len = " + string(len(fruits));

    let nums = [3, 1, 4, 1, 5];
    array_push(nums, 9);
    print "after push len = " + string(len(nums));
    let popped = array_pop(nums);
    print "popped = " + string(popped);

    let sorted = array_sort(nums);
    print "sorted[0] = " + string(sorted[0]);
    print "sorted[1] = " + string(sorted[1]);

    let reversed = array_reverse(sorted);
    print "reversed[0] = " + string(reversed[0]);

    // iteration using range
    let sum = 0;
    for i in 0..len(nums) {
        sum = sum + nums[i];
    }
    print "sum = " + string(sum);
}
