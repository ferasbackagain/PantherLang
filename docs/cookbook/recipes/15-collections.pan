panther main {
    let arr = [5, 3, 8, 1, 9, 2];

    array_push(arr, 7);
    print "after push len: " + string(len(arr));

    let val = array_pop(arr);
    print "popped: " + string(val);

    let sorted = array_sort(arr);
    print "sorted first: " + string(sorted[0]);
    print "sorted last: " + string(sorted[len(sorted) - 1]);

    let reversed = array_reverse(arr);
    print "reversed first: " + string(reversed[0]);
    print "reversed last: " + string(reversed[len(reversed) - 1]);

    let obj = {items: [10, 20, 30], label: "numbers"};
    array_push(obj["items"], 40);
    print "obj items len: " + string(len(obj["items"]));
}
