"""PantherLang Phase 6.6 native backend integration."""
from .target import NativeTarget, TargetRegistry
from .ir_model import NativeInstruction, NativeFunction, NativeModule
from .emitter import NativeEmitter, EmissionResult
from .linker import NativeLinker, LinkResult
from .backend import PantherNativeBackend, NativeBuildResult
__all__=["NativeTarget","TargetRegistry","NativeInstruction","NativeFunction","NativeModule","NativeEmitter","EmissionResult","NativeLinker","LinkResult","PantherNativeBackend","NativeBuildResult"]
