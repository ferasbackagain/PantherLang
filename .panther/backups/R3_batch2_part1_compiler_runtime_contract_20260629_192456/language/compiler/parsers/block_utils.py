import re


def extract_named_blocks(source, keyword):
    pattern = re.compile(rf"{keyword}\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{{(.*?)\}}", re.S)
    return pattern.findall(source)


def extract_app(source):
    m = re.search(r"app\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{(.*?)\}", source, re.S)
    return m.groups() if m else None


def extract_api(source):
    pattern = re.compile(r"api\s+(GET|POST|PUT|PATCH|DELETE)\s+([^\s\{]+)\s*\{(.*?)\}", re.S)
    return pattern.findall(source)


def clean_lines(block):
    return [line.strip() for line in block.splitlines() if line.strip()]
