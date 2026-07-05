panther main {
    print "=== Lesson 06: Data Structures ===";
    print "";
    
    print "--- Arrays ---";
    let numbers = [10, 20, 30, 40, 50];
    print "numbers: " + to_string(numbers);
    print "length: " + to_string(len(numbers));
    print "first: " + to_string(numbers[0]);
    print "last: " + to_string(numbers[len(numbers) - 1]);
    print "";
    
    print "--- Array Iteration ---";
    let sum = 0;
    for i in 0..len(numbers) {
        sum = sum + numbers[i];
    }
    print "sum: " + to_string(sum);
    print "";
    
    print "--- Array Methods ---";
    let fruits = ["apple", "banana"];
    print "before push: " + to_string(fruits);
    array_push(fruits, "cherry");
    print "after push: " + to_string(fruits);
    let popped = array_pop(fruits);
    print "popped: " + popped;
    print "after pop: " + to_string(fruits);
    print "";
    
    print "--- Array Sorting ---";
    let unsorted = [5, 2, 8, 1, 9];
    print "unsorted: " + to_string(unsorted);
    array_sort(unsorted);
    print "sorted: " + to_string(unsorted);
    array_reverse(unsorted);
    print "reversed: " + to_string(unsorted);
    print "";
    
    print "--- Objects / Dictionaries ---";
    let person = {
        name: "Alice",
        age: 30,
        city: "New York",
        active: true
    };
    print "person: " + to_string(person);
    print "name: " + person["name"];
    print "age: " + to_string(person["age"]);
    print "city: " + person["city"];
    print "";
    
    print "--- Nested Objects ---";
    let config = {
        database: {
            host: "localhost",
            port: 5432,
            name: "myapp"
        },
        cache: {
            enabled: true,
            ttl: 300
        }
    };
    print "db host: " + config["database"]["host"];
    print "cache ttl: " + to_string(config["cache"]["ttl"]);
    print "";
    
    print "--- Object Keys Access ---";
    let scores = {"alice": 95, "bob": 87, "charlie": 92};
    print "alice: " + to_string(scores["alice"]);
    print "bob: " + to_string(scores["bob"]);
    print "charlie: " + to_string(scores["charlie"]);
    print "";
    
    print "--- Structs ---";
    struct Point {
        x y
    }
    
    let p1 = Point(10, 20);
    let p2 = Point(30, 40);
    print "p1: (" + to_string(p1.x) + ", " + to_string(p1.y) + ")";
    print "p2: (" + to_string(p2.x) + ", " + to_string(p2.y) + ")";
    print "";
    
    print "--- Struct with Methods Pattern ---";
    struct Rectangle {
        width height
    }
    
    let rect = Rectangle(10, 5);
    let area = rect.width * rect.height;
    print "rectangle area: " + to_string(area);
    print "";
    
    print "--- Mixed Collections ---";
    let data = {
        numbers: [1, 2, 3],
        user: {name: "test", id: 42},
        tags: ["tag1", "tag2"]
    };
    print "first number: " + to_string(data["numbers"][0]);
    print "user name: " + data["user"]["name"];
    print "first tag: " + data["tags"][0];
    print "";
    
    print "=== Lesson 06 Complete ===";
}