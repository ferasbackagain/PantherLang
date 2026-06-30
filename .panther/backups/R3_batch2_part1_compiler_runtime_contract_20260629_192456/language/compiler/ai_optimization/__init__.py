"""PantherLang Phase 6.7 AI compiler optimization."""
from .ir import OptimizationNode, OptimizationUnit
from .passes import OptimizationPass, ConstantFoldingPass, DeadCodeEliminationPass, AgentHintPass, PassManager
from .cost_model import AICostModel, CostEstimate
from .optimizer import PantherAICompilerOptimizer, OptimizationResult
__all__=["OptimizationNode","OptimizationUnit","OptimizationPass","ConstantFoldingPass","DeadCodeEliminationPass","AgentHintPass","PassManager","AICostModel","CostEstimate","PantherAICompilerOptimizer","OptimizationResult"]
