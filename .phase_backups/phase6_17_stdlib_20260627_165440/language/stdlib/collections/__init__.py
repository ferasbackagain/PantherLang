def count(items):
    return len(items)

def first(items):
    return items[0] if items else None

def last(items):
    return items[-1] if items else None

def unique(items):
    return list(dict.fromkeys(items))
