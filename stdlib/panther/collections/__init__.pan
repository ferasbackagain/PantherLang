panther main {
    // Array operations
    fn panther_collections_array_len(arr) {
        return len(arr);
    }

    fn panther_collections_array_push(arr, item) {
        return array_push(arr, item);
    }

    fn panther_collections_array_pop(arr) {
        return array_pop(arr);
    }

    fn panther_collections_array_get(arr, index) {
        return arr[index];
    }

    fn panther_collections_array_set(arr, index, value) {
        arr[index] = value;
        return arr;
    }

    // No slice - not supported

    fn panther_collections_array_contains(arr, item) {
        let n = len(arr);
        for i in 0..n {
            if arr[i] == item {
                return true;
            }
        }
        return false;
    }

    fn panther_collections_array_index_of(arr, item) {
        let n = len(arr);
        for i in 0..n {
            if arr[i] == item {
                return i;
            }
        }
        return -1;
    }

    fn panther_collections_array_reverse(arr) {
        return array_reverse(arr);
    }

    fn panther_collections_array_sort(arr) {
        return array_sort(arr);
    }

    fn panther_collections_array_map(arr, callback) {
        let result = [];
        let n = len(arr);
        for i in 0..n {
            result = array_push(result, callback(arr[i]));
        }
        return result;
    }

    fn panther_collections_array_filter(arr, predicate) {
        let result = [];
        let n = len(arr);
        for i in 0..n {
            if predicate(arr[i]) {
                result = array_push(result, arr[i]);
            }
        }
        return result;
    }

    fn panther_collections_array_reduce(arr, reducer, initial) {
        let acc = initial;
        let n = len(arr);
        for i in 0..n {
            acc = reducer(acc, arr[i]);
        }
        return acc;
    }

    fn panther_collections_array_join(arr, sep) {
        return join(sep, arr);
    }

    fn panther_collections_array_concat(arr1, arr2) {
        let result = [];
        let n1 = len(arr1);
        let n2 = len(arr2);
        for i in 0..n1 {
            result = array_push(result, arr1[i]);
        }
        for i in 0..n2 {
            result = array_push(result, arr2[i]);
        }
        return result;
    }

    fn panther_collections_array_flatten(arr) {
        let result = [];
        let n = len(arr);
        for i in 0..n {
            let x = arr[i];
            if type_of(x) == "array" {
                let m = len(x);
                for j in 0..m {
                    result = array_push(result, x[j]);
                }
            } else {
                result = array_push(result, x);
            }
        }
        return result;
    }

    // Range - use while loop
    fn panther_collections_range(start, end, step) {
        if step == 0 {
            step = 1;
        }
        let result = [];
        let i = start;
        if step > 0 {
            while i < end {
                if i % step == 0 {
                    result = array_push(result, i);
                }
                i = i + 1;
            }
        } else {
            while i > end {
                if i % step == 0 {
                    result = array_push(result, i);
                }
                i = i - 1;
            }
        }
        return result;
    }
}