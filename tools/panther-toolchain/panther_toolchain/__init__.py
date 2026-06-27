"""PantherLang cross-platform toolchain support."""
from .targets import TargetTriple, TARGETS, parse_target
from .resolver import ToolchainResolver
from .builder import CrossPlatformBuilder
