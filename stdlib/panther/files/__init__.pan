panther main {
    fn panther_files_read(path) {
        return read_file(path);
    }

    fn panther_files_write(path, content) {
        return fs_write(path, content);
    }

    fn panther_files_append(path, content) {
        return fs_append(path, content);
    }

    fn panther_files_exists(path) {
        return file_exists(path);
    }

    fn panther_files_mkdir(path) {
        return fs_mkdir(path);
    }

    fn panther_files_copy(src, dst) {
        return fs_copy(src, dst);
    }

    fn panther_files_move(src, dst) {
        return fs_move(src, dst);
    }

    fn panther_files_remove(path) {
        return fs_remove(path);
    }

    fn panther_files_rename(src, dst) {
        return fs_rename(src, dst);
    }

    fn panther_files_listdir(path) {
        return fs_listdir(path);
    }

    fn panther_files_cwd() {
        return fs_cwd();
    }

    fn panther_files_absolute(path) {
        return fs_absolute(path);
    }

    fn panther_files_is_file(path) {
        return fs_is_file(path);
    }

    fn panther_files_is_dir(path) {
        return fs_is_dir(path);
    }

    fn panther_files_basename(path) {
        return fs_basename(path);
    }

    fn panther_files_dirname(path) {
        return fs_dirname(path);
    }

    fn panther_files_extension(path) {
        return fs_extension(path);
    }

    fn panther_files_join(a, b) {
        return fs_join(a, b);
    }

    fn panther_files_tempdir() {
        return fs_tempdir();
    }

    fn panther_files_tempfile(suffix) {
        return fs_tempfile(suffix);
    }

    fn panther_files_stat(path) {
        return fs_stat(path);
    }

    fn panther_files_walk(path) {
        return fs_walk(path);
    }
}