from pathlib import Path
import pytest
from language.compiler.native_backend import PantherNativeBackend, TargetRegistry, NativeTarget
from language.compiler.native_backend.ir_model import NativeModule, NativeFunction, NativeInstruction
from language.compiler.integration.native_backend_integration import compile_to_native
def test_target_registry_lists_core_targets():
    targets=TargetRegistry().list_targets(); assert "x86_64-unknown-linux-gnu" in targets; assert "wasm32-unknown-unknown" in targets
def test_emit_and_link_native_build(tmp_path):
    r=PantherNativeBackend(output_root=tmp_path).build('let x = 1\nprint x', module_name='demo')
    assert r.success is True; assert Path(r.object['artifact_path']).exists(); assert Path(r.executable['executable_path']).exists(); assert r.executable['object_count']==1
def test_integration_adapter_returns_report():
    report=compile_to_native('print "hello"', module_name='adapter_demo'); assert report['success'] is True; assert report['target']=='x86_64-unknown-linux-gnu'
def test_invalid_target_rejected():
    with pytest.raises(KeyError): PantherNativeBackend().build('print 1', 'bad-target')
def test_empty_source_negative():
    with pytest.raises(ValueError): PantherNativeBackend().build('   ')
def test_invalid_module_validation():
    with pytest.raises(ValueError): NativeModule('', [NativeFunction('main',[NativeInstruction('noop')])]).validate()
def test_custom_target_registration():
    reg=TargetRegistry(); reg.register(NativeTarget('x86_64-custom-lab','x86_64','linux')); assert reg.get('x86_64-custom-lab').arch=='x86_64'
