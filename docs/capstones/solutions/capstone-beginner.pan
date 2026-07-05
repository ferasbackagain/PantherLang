panther main {
    print "=== Personal Diary CLI ===";
    print "";

    let diary_dir = "diary_entries";
    mkdir(diary_dir);

    fn save_entry(date, content) {
        let filename = diary_dir + "/" + date + ".txt";
        write_file(filename, content);
        return "Entry saved for " + date;
    }

    fn list_entries() {
        let files = list_dir(diary_dir);
        if len(files) == 0 {
            return "No diary entries found";
        }
        let result = "Entries (" + string(len(files)) + "):";
        let i = 0;
        while i < len(files) {
            let f = files[i];
            let name = replace(f, ".txt", "");
            result = result + "\n  " + string(i + 1) + ". " + name;
            i = i + 1;
        }
        return result;
    }

    fn search_by_date(date) {
        let filename = diary_dir + "/" + date + ".txt";
        if file_exists(filename) {
            return "Entry for " + date + ":\n" + read_file(filename);
        }
        return "No entry found for " + date;
    }

    save_entry("2026-01-15", "Started learning PantherLang today. The syntax is clean and intuitive.");
    save_entry("2026-01-16", "Built my first web app with PantherLang. The web framework is simple yet powerful.");
    save_entry("2026-01-17", "Explored the type system. Explicit conversion between types works well.");

    print list_entries();
    print "";
    print search_by_date("2026-01-15");
    print "";
    print search_by_date("2026-01-16");

    print "";
    print "=== Diary CLI Demo Complete ===";
}
