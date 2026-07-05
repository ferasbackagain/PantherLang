panther main {
    let gradebook = {
        Alice: [85, 92, 78],
        Bob: [90, 88, 95],
        Carol: [70, 85, 89]
    };

    let students = ["Alice", "Bob", "Carol"];
    let class_total = 0;
    let class_count = 0;

    for s in 0..len(students) {
        let name = students[s];
        let scores = gradebook[name];
        print name;
        print scores;

        let student_sum = 0;
        for i in 0..len(scores) {
            student_sum = student_sum + scores[i];
        }
        let avg = student_sum * 1.0 / len(scores);
        print "Average: " + string(avg);
        class_total = class_total + student_sum;
        class_count = class_count + len(scores);
    }

    let class_avg = class_total * 1.0 / class_count;
    print "Class Average: " + string(class_avg);

    let library = {
        fiction: {count: 5, books: ["Dune", "1984", "Neuromancer", "Ender's Game", "Snow Crash"]},
        non_fiction: {count: 3, books: ["Sapiens", "Homo Deus", "21 Lessons"]}
    };

    print library["fiction"]["books"][0];
    print library["non_fiction"]["count"];

    for i in 0..len(library["fiction"]["books"]) {
        print library["fiction"]["books"][i];
    }
    for i in 0..len(library["non_fiction"]["books"]) {
        print library["non_fiction"]["books"][i];
    }
}
