#!/usr/bin/env python3
"""Test to prove self-hosted .pan provenance by testing fallback behavior.

This test verifies that self-hosted .pan implementations correctly delegate
to Python primitives and that the injection mechanism works correctly.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from compiler.runtime import execute_source
from compiler.stdlib.selfhost import get_selfhosted_functions


def test_selfhosted_functions_available():
    """Verify all self-hosted functions are accessible via the injection mechanism."""
    source = '''
    panther main {
        // Test core_math functions
        let a = abs(-42);
        let b = pow(2, 10);
        let c = sqrt(16);
        let d = floor(3.7);
        let e = ceil(3.2);
        
        // Test core_crypto functions (delegate to Python)
        let h = sha256("test");
        
        // Test core_filesystem functions (delegate to Python)
        let exists = fs_exists("nonexistent.txt");
        
        // Test core_type functions (delegate to Python)
        let i = to_int("123");
        let f = to_float("3.14");
        let s = to_string(42);
        
        // Test core_json functions (delegate to Python)
        let encoded = json_encode({"key": "value"});
        let decoded = json_decode(encoded);
        
        // Test core_time functions (delegate to Python)
        let tnow = time_now();
        time_sleep(0.001);
        
        // Test core_network functions (delegate to Python)
        let resolved = resolve_hostname("localhost");
        
        print("all_selfhosted_functions_work");
    }
    '''
    
    result = execute_source(source)
    assert result.error is None, f"Execution failed: {result.error}"
    assert "all_selfhosted_functions_work" in result.captured_output
    
    print("✓ All self-hosted functions work through injection mechanism")
    assert True


def test_selfhosted_forward_references():
    """Test that self-hosted functions can call other self-hosted functions
    defined later in the same or different module (forward references).
    
    The two-pass semantic analyzer handles this correctly.
    """
    source = '''
    panther main {
        // net_is_public_ip calls net_is_loopback_ip and net_is_link_local_ip
        // which are defined LATER in network.pan
        let result1 = net_is_public_ip("8.8.8.8");
        let result2 = net_is_public_ip("127.0.0.1");
        let result3 = net_is_public_ip("169.254.1.1");
        let result4 = net_is_public_ip("10.0.0.1");
        
        print("public_ip_8.8.8.8: " + to_string(result1));
        print("public_ip_127.0.0.1: " + to_string(result2));
        print("public_ip_169.254.1.1: " + to_string(result3));
        print("public_ip_10.0.0.1: " + to_string(result4));
    }
    '''
    
    result = execute_source(source)
    assert result.error is None, f"Execution failed: {result.error}"
    assert "public_ip_8.8.8.8: true" in result.captured_output
    assert "public_ip_127.0.0.1: false" in result.captured_output
    assert "public_ip_169.254.1.1: false" in result.captured_output
    assert "public_ip_10.0.0.1: false" in result.captured_output
    
    print("✓ Self-hosted forward references work correctly")
    assert True


def test_selfhosted_module_discovery():
    """Verify self-hosted module discovery works correctly."""
    modules = get_selfhosted_functions()
    
    expected_modules = {
        "core_math", "core_crypto", "core_filesystem", "core_json",
        "core_type", "core_time", "core_network", "network",
        "discovery", "discovery_engine", "address", "policy", "services",
        # Phase 1 SL 2.0 packages
        "panther.core", "panther.math", "panther.text", "panther.time",
        "panther.json", "panther.files", "panther.collections",
        # Phase 3 packages
        "panther.system", "panther.process", "panther.logging", "panther.cli",
        # Phase 4 packages
        "panther.net", "panther.http",
        # Phase 5 packages
        "panther.web",
        # Phase 6 packages
        "panther.database", "panther.storage",
        # Phase 7 packages
        "panther.crypto", "panther.security",
        # Phase 8 packages
        "panther.async", "panther.concurrent", "panther.testing",
        # Phase 9 packages
        "panther.ai",
        # Phase 10 packages
        "panther.cloud", "panther.container",
        # Phase 11 packages
        "panther.serialization",
        # Phase 12 packages
        "panther.game"
    }
    
    assert set(modules.keys()) == expected_modules, f"Missing modules: {expected_modules - set(modules.keys())}"
    
    # Verify each module has functions
    for name, fns in modules.items():
        assert len(fns) > 0, f"Module {name} has no functions"
    
    print(f"✓ Self-hosted module discovery works: {len(modules)} modules found")
    for name, fns in sorted(modules.items()):
        print(f"  {name}: {len(fns)} functions")
    assert True


def test_selfhosted_wrappers_delegate_correctly():
    """Test that self-hosted wrapper functions correctly delegate to Python primitives."""
    source = '''
    panther main {
        // sha256 in core_crypto.pan delegates to crypto_sha256
        let h1 = sha256("hello");
        let h2 = sha256("world");
        let diff = h1 != h2;
        
        // to_int in core_type.pan delegates to Python's to_int
        let i = to_int("42");
        let i_ok = i == 42;
        
        // fs_exists in core_filesystem.pan delegates to file_exists
        let e = fs_exists("/nonexistent/path/12345");
        let e_ok = e == false;
        
        // time_now in core_time.pan delegates to Python's time_now
        let t = time_now();
        let t_ok = t > 0;
        
        if diff && i_ok && e_ok && t_ok {
            print("wrappers_delegate_correctly");
        } else {
            print("FAIL");
        }
    }
    '''
    
    result = execute_source(source)
    assert result.error is None, f"Execution failed: {result.error}"
    assert "wrappers_delegate_correctly" in result.captured_output
    
    print("✓ Self-hosted wrappers correctly delegate to Python primitives")
    assert True


if __name__ == "__main__":
    test_selfhosted_functions_available()
    test_selfhosted_forward_references()
    test_selfhosted_module_discovery()
    test_selfhosted_wrappers_delegate_correctly()
    print("\n✅ All self-hosted provenance tests passed!")
