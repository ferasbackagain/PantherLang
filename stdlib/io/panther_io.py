def println(value):
    return str(value)

def read_text(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()
