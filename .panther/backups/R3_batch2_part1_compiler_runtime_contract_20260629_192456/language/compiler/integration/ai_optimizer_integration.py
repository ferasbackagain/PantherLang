from __future__ import annotations
from typing import Dict
from language.compiler.ai_optimization import PantherAICompilerOptimizer
def optimize_with_ai_compiler(source: str, unit_name: str="main") -> Dict[str, object]:
    return PantherAICompilerOptimizer().optimize_source(source, unit_name).to_dict()
