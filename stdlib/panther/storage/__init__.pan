panther main {
    // Storage operations (using existing storage_* functions)
    fn panther_storage_open(path) {
        return storage_open(path);
    }

    fn panther_storage_put(store, key, data) {
        return storage_put(store, key, data);
    }

    fn panther_storage_get(store, key) {
        return storage_get(store, key);
    }

    fn panther_storage_exists(store, key) {
        return storage_exists(store, key);
    }

    fn panther_storage_delete(store, key) {
        return storage_delete(store, key);
    }

    fn panther_storage_list(store, prefix) {
        if prefix == null {
            return storage_list(store);
        }
        return storage_list(store, prefix);
    }

    // JSON storage helpers
    fn panther_storage_put_json(store, key, value) {
        return storage_put(store, key, json_stringify(value));
    }

    fn panther_storage_get_json(store, key) {
        let data = storage_get(store, key);
        if data != "" {
            return json_parse(data);
        }
        return null;
    }

    // Batch operations
    fn panther_storage_put_batch(store, items) {
        // items: array of {key: "", value: ""}
        let ok = true;
        let i = 0;
        while i < len(items) {
            let item = items[i];
            if !storage_put(store, item.key, item.value) {
                ok = false;
                break;
            }
            i = i + 1;
        }
        return ok;
    }

    fn panther_storage_get_batch(store, keys) {
        let results = {};
        let i = 0;
        while i < len(keys) {
            let key = keys[i];
            results[key] = storage_get(store, key);
            i = i + 1;
        }
        return results;
    }

    fn panther_storage_delete_batch(store, keys) {
        let ok = true;
        let i = 0;
        while i < len(keys) {
            if !storage_delete(store, keys[i]) {
                ok = false;
            }
            i = i + 1;
        }
        return ok;
    }

    // Prefix-based operations
    fn panther_storage_get_prefix(store, prefix) {
        let keys = storage_list(store, prefix);
        let results = {};
        let i = 0;
        while i < len(keys) {
            let key = keys[i];
            results[key] = storage_get(store, key);
            i = i + 1;
        }
        return results;
    }

    fn panther_storage_delete_prefix(store, prefix) {
        let keys = storage_list(store, prefix);
        let i = 0;
        while i < len(keys) {
            storage_delete(store, keys[i]);
            i = i + 1;
        }
        return len(keys);
    }

    // Metadata
    fn panther_storage_count(store) {
        return len(storage_list(store));
    }

    fn panther_storage_keys(store, prefix) {
        return storage_list(store, prefix);
    }

    fn panther_storage_size(store) {
        let keys = storage_list(store);
        let total = 0;
        let i = 0;
        while i < len(keys) {
            let data = storage_get(store, keys[i]);
            total = total + len(data);
            i = i + 1;
        }
        return total;
    }

    // Namespace/collection support
    fn panther_storage_collection(store, collection_name) {
        return {store: store, prefix: collection_name + "/"};
    }

    fn panther_storage_coll_put(coll, key, data) {
        return storage_put(coll.store, coll.prefix + key, data);
    }

    fn panther_storage_coll_get(coll, key) {
        return storage_get(coll.store, coll.prefix + key);
    }

    fn panther_storage_coll_exists(coll, key) {
        return storage_exists(coll.store, coll.prefix + key);
    }

    fn panther_storage_coll_delete(coll, key) {
        return storage_delete(coll.store, coll.prefix + key);
    }

    fn panther_storage_coll_list(coll) {
        return storage_list(coll.store, coll.prefix);
    }

    fn panther_storage_coll_count(coll) {
        return len(panther_storage_coll_list(coll));
    }

    // TTL support (using metadata file)
    fn panther_storage_put_ttl(store, key, data, ttl_seconds) {
        let expiry = time() + ttl_seconds;
        let wrapper = {data: data, expiry: expiry};
        return storage_put(store, key, json_stringify(wrapper));
    }

    fn panther_storage_get_ttl(store, key) {
        let data = storage_get(store, key);
        if data == "" {
            return null;
        }
        let wrapper = json_parse(data);
        if wrapper == null {
            return data; // Backwards compatibility
        }
        if time() > wrapper.expiry {
            storage_delete(store, key);
            return null;
        }
        return wrapper.data;
    }

    fn panther_storage_cleanup_expired(store) {
        let keys = storage_list(store);
        let cleaned = 0;
        let i = 0;
        while i < len(keys) {
            let data = storage_get(store, keys[i]);
            if data != "" {
                let wrapper = json_parse(data);
                if wrapper != null && wrapper.expiry != null {
                    if time() > wrapper.expiry {
                        storage_delete(store, keys[i]);
                        cleaned = cleaned + 1;
                    }
                }
            }
            i = i + 1;
        }
        return cleaned;
    }
}