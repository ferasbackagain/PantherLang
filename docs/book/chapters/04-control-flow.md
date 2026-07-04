# Chapter 4: Control Flow

## If / Elif / Else

```panther
let x = 10;
if x > 10 {
    print "greater";
} elif x == 10 {
    print "equal";
} else {
    print "less";
}
```

## While Loops

```panther
let i = 0;
while i < 5 {
    print i;
    i = i + 1;
}
```

## For Range Loops

```panther
for i in 0..5 {
    print i;    // 0, 1, 2, 3, 4
}
```

## Infinite Loop

```panther
loop {
    // infinite loop
    break;      // exit the loop
}
```

## Break and Continue

```panther
let i = 0;
while i < 10 {
    i = i + 1;
    if i == 3 {
        continue;    // skip iteration
    }
    if i == 7 {
        break;       // exit loop
    }
    print i;         // 1, 2, 4, 5, 6
}
```
