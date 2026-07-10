#!/usr/bin/env python3
"""Generate exact Panther/Python/native/external dependency matrices."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.capability_manifest import (
    get_manifest,
    list_capabilities,
    list_stdlib_functions,
    list_selfhosted_modules,
    list_native_backends,
)


def generate_dependency_matrices():
    """Generate all dependency matrices."""
    manifest = get_manifest()
    
    matrices = {}
    
    # 1. Panther stdlib -> Python primitives matrix
    python_primitives = {}
    for fn in manifest["stdlib_functions"]:
        name = fn["name"]
        impl = fn["implementation"]
        fallback = fn["fallback"]
        if impl == "python":
            python_primitives[name] = {"type": "direct", "fallback": None}
        elif impl == "native":
            python_primitives[name] = {"type": "native", "fallback": fallback or "python"}
        elif impl == "selfhost":
            python_primitives[name] = {"type": "selfhost", "fallback": fallback or "python"}
    
    matrices["panther_to_python"] = python_primitives
    
    # 2. Self-hosted modules -> Python primitives matrix
    selfhosted_matrix = {}
    for mod in manifest["selfhosted_modules"]:
        name = mod["name"]
        selfhosted_matrix[name] = {
            "functions": mod["functions"],
            "dependencies": []
        }
        # Add known dependencies for each module
        if name == "core_math":
            selfhosted_matrix[name]["dependencies"] = ["<", "**", "-", "to_int", "to_float"]
        elif name == "core_crypto":
            selfhosted_matrix[name]["dependencies"] = ["crypto_sha256", "crypto_sha512", "crypto_md5", "crypto_hmac_sha256", "crypto_uuid", "crypto_random_bytes", "crypto_secure_random_int", "crypto_base64_encode", "crypto_base64_decode", "crypto_hex_encode", "crypto_hex_decode"]
        elif name == "core_filesystem":
            selfhosted_matrix[name]["dependencies"] = ["read_file", "write_file", "file_exists", "mkdir", "list_dir"]
        elif name == "core_json":
            selfhosted_matrix[name]["dependencies"] = ["json_stringify", "json_parse"]
        elif name == "core_type":
            selfhosted_matrix[name]["dependencies"] = ["to_int", "to_float", "to_string"]
        elif name == "core_time":
            selfhosted_matrix[name]["dependencies"] = ["time_now", "time_sleep"]
        elif name == "core_network":
            selfhosted_matrix[name]["dependencies"] = ["net_resolve", "net_reverse_resolve", "net_port_check"]
        elif name == "network":
            selfhosted_matrix[name]["dependencies"] = ["starts_with"]
        elif name == "address":
            selfhosted_matrix[name]["dependencies"] = ["split", "len", "to_int", "net_resolve"]
        elif name == "policy":
            selfhosted_matrix[name]["dependencies"] = ["net_is_loopback_ip", "net_is_link_local_ip", "net_is_private_ip"]
        elif name == "discovery":
            selfhosted_matrix[name]["dependencies"] = ["len", "array_push", "net_port_to_service_name", "net_service_confidence", "net_reverse_resolve"]
        elif name == "discovery_engine":
            selfhosted_matrix[name]["dependencies"] = ["len", "tcp_connect", "time_now", "net_port_to_service_name", "net_service_confidence", "net_reverse_resolve", "tcp_banner", "contains", "split", "array_push"]
        elif name == "services":
            selfhosted_matrix[name]["dependencies"] = ["contains", "net_reverse_resolve", "tcp_banner", "split", "len", "net_port_to_service_name", "net_service_confidence"]
    
    matrices["selfhosted_to_python"] = selfhosted_matrix
    
    # 3. Native backends matrix
    native_matrix = {}
    for backend in manifest["native_backends"]:
        name = backend["name"]
        native_matrix[name] = {
            "library": backend["library"],
            "functions": backend["functions"],
            "platforms": backend["supported_platforms"],
            "fallback": "python"
        }
    
    matrices["native_backends"] = native_matrix
    
    # 4. Host capabilities matrix
    host_matrix = {}
    for cap in manifest["host_abilities"]:
        name = cap["name"]
        host_matrix[name] = {
            "description": cap["description"],
            "available": cap["available"],
            "requires_network": cap["requires_network"],
            "category": cap["category"]
        }
    
    matrices["host_capabilities"] = host_matrix
    
    # 5. External dependencies matrix
    external_matrix = {
        "libc": ["open", "read", "write", "close", "mkdir", "unlink", "rename", "access", "clock_gettime", "nanosleep", "socket", "connect", "setsockopt"],
        "libcrypto": ["SHA256"],
        "python_stdlib": list(get_python_stdlib_functions()),
    }
    
    matrices["external_dependencies"] = external_matrix
    
    return matrices


def get_python_stdlib_functions():
    """Get list of Python stdlib function names."""
    from compiler.stdlib import get_stdlib_functions
    return list(get_stdlib_functions().keys())


def main():
    matrices = generate_dependency_matrices()
    
    output = {
        "version": "1.1.7",
        "generated_by": "dependency_matrix_generator.py",
        "matrices": matrices,
        "summary": {
            "panther_stdlib_functions": len(matrices["panther_to_python"]),
            "selfhosted_modules": len(matrices["selfhosted_to_python"]),
            "native_backends": len(matrices["native_backends"]),
            "host_capabilities": len(matrices["host_capabilities"]),
            "external_libraries": len(matrices["external_dependencies"]),
        }
    }
    
    # Write to JSON file
    output_path = Path(__file__).resolve().parents[1] / "engineering" / "DEPENDENCY_MATRICES.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(output, indent=2, sort_keys=True))
    
    print(f"Dependency matrices written to {output_path}")
    print(json.dumps(output["summary"], indent=2))
    
    return 0


if __name__ == "__main__":
    sys.exit(main())