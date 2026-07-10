panther main {
    fn fs_read_text(path) {
        return read_file(path);
    }

    fn fs_write_text(path, content) {
        write_file(path, content);
    }

    fn fs_exists(path) {
        return file_exists(path);
    }

    fn fs_mkdir(path) {
        mkdir(path);
    }

    fn fs_list(path) {
        return list_dir(path);
    }

    fn fs_copy(src, dst) {
        fs_write_text(dst, fs_read_text(src));
    }
}
