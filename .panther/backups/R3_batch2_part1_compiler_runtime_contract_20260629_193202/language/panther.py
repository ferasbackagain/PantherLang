#!/usr/bin/env python3
import json
import sys
from pathlib import Path

from compiler.core.tokenizer import tokenize, TokenizerError
from compiler.core.parser import parse_tokens, ParserError
from compiler.core.semantic import build_semantic_model
from compiler.core.ir import semantic_to_ir
from runtime.server import run_server

VERSION = "0.5.0"

def read_source(path):
    p = Path(path)
    if not p.exists():
        print(f"❌ File not found: {path}")
        sys.exit(1)
    return p.read_text(), p

def parse_file(path):
    source, p = read_source(path)
    tokens = tokenize(source)
    program = parse_tokens(tokens)
    semantic = build_semantic_model(program)
    return tokens, program, semantic, p

def command_check(path):
    try:
        _, _, semantic, p = parse_file(path)
    except (TokenizerError, ParserError) as e:
        print(f"❌ PantherLang check failed: {e}")
        sys.exit(1)
    print("🐾 PantherLang v0.5")
    print(f"Checking: {p}")
    print("-" * 50)
    print(f"✅ app: {semantic.app_name}")
    for model in semantic.data_models:
        print(f"✅ data: {model.name} ({len(model.fields)} fields)")
    for api in semantic.apis:
        print(f"✅ api: {api.method} {api.path} -> {api.action} {api.model}")
    for page in semantic.pages:
        print(f"✅ ui: page {page.name}")
    print("-" * 50)
    print("✅ PantherLang semantic model is valid.")

def command_tokens(path):
    tokens, _, _, _ = parse_file(path)
    for token in tokens:
        print(token)

def command_ast(path):
    _, program, _, _ = parse_file(path)
    print(json.dumps(program.to_dict(), indent=2))

def command_semantic(path):
    _, _, semantic, _ = parse_file(path)
    print(json.dumps(semantic.to_dict(), indent=2))

def command_ir(path):
    _, _, semantic, _ = parse_file(path)
    print(json.dumps(semantic_to_ir(semantic), indent=2))

def command_run(path):
    _, _, semantic, _ = parse_file(path)
    run_server(semantic)

def command_doctor():
    print("🐾 PantherLang Doctor")
    print(f"Version: {VERSION}")
    print(f"Python: {sys.version.split()[0]}")
    print("Required external packages: none")
    print("Status: ✅ OK")

def usage():
    print(f"""PantherLang CLI v{VERSION}

Usage:
  python3 panther.py doctor
  python3 panther.py check <file.panther>
  python3 panther.py tokens <file.panther>
  python3 panther.py ast <file.panther>
  python3 panther.py semantic <file.panther>
  python3 panther.py ir <file.panther>
  python3 panther.py run <file.panther>
""")

def main():
    if len(sys.argv) < 2:
        usage()
        return
    cmd = sys.argv[1]
    if cmd == "doctor":
        command_doctor()
        return
    if len(sys.argv) < 3:
        usage()
        sys.exit(1)
    path = sys.argv[2]
    if cmd == "check":
        command_check(path)
    elif cmd == "tokens":
        command_tokens(path)
    elif cmd == "ast":
        command_ast(path)
    elif cmd == "semantic":
        command_semantic(path)
    elif cmd == "ir":
        command_ir(path)
    elif cmd == "run":
        command_run(path)
    else:
        print(f"❌ Unknown command: {cmd}")
        usage()
        sys.exit(1)

if __name__ == "__main__":
    main()
