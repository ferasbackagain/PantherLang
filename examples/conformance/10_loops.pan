panther main {
    let i = 0;
    while i < 3 {
        print i;
        i = i + 1;
    }

    for j in 0..4 {
        print j;
    }

    let k = 0;
    loop {
        k = k + 1;
        if k == 3 {
            continue;
        }
        if k == 5 {
            break;
        }
        print k;
    }
}
