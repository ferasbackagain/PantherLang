panther main {
    print "=== Panther Task Manager ===";
    let data_dir = "task_data";
    let data_file = data_dir + "/tasks.json";
    mkdir(data_dir);

    if file_exists(data_file) {
        remove_file(data_file);
    }

    let tasks = [];
    write_file(data_file, json_encode(tasks));

    let mode = "add";
    let task_text = "Buy groceries";
    print "Mode: " + mode;
    if mode == "add" {
        let new_id = len(tasks) + 1;
        let n = array_push(tasks, {id: new_id, text: task_text, done: false});
        write_file(data_file, json_encode(tasks));
        print "[ADD] Task added: " + task_text;
    }

    task_text = "Write documentation";
    if mode == "add" {
        let new_id = len(tasks) + 1;
        let n = array_push(tasks, {id: new_id, text: task_text, done: false});
        write_file(data_file, json_encode(tasks));
        print "[ADD] Task added: " + task_text;
    }

    task_text = "Review PR";
    if mode == "add" {
        let new_id = len(tasks) + 1;
        let n = array_push(tasks, {id: new_id, text: task_text, done: false});
        write_file(data_file, json_encode(tasks));
        print "[ADD] Task added: " + task_text;
    }

    mode = "list";
    print "Mode: " + mode;
    tasks = json_decode(read_file(data_file));
    let i = 0;
    while i < len(tasks) {
        let t = tasks[i];
        let status = " ";
        if t["done"] { status = "X"; }
        print "  [" + status + "] " + string(t["id"]) + ": " + t["text"];
        i = i + 1;
    }

    mode = "complete";
    print "Mode: " + mode;
    tasks = json_decode(read_file(data_file));
    let j = 0;
    while j < len(tasks) {
        if tasks[j]["id"] == 1 {
            tasks[j]["done"] = true;
        }
        j = j + 1;
    }
    write_file(data_file, json_encode(tasks));
    print "[DONE] Task 1 completed";

    mode = "delete";
    print "Mode: " + mode;
    tasks = json_decode(read_file(data_file));
    let removed = array_pop(tasks);
    write_file(data_file, json_encode(tasks));
    print "[DEL] Removed task: " + removed["text"];

    mode = "list";
    print "Mode: " + mode;
    tasks = json_decode(read_file(data_file));
    let texts = ["Buy groceries", "Write documentation"];
    let sorted_texts = array_sort(texts);
    print "  Sorted tasks: " + join(", ", sorted_texts);
    let k = 0;
    while k < len(tasks) {
        let t = tasks[k];
        let status = " ";
        if t["done"] { status = "X"; }
        print "  [" + status + "] " + string(t["id"]) + ": " + t["text"];
        k = k + 1;
    }

    print "=== Task Manager Complete ===";
}
