from pathlib import Path
import pytest
from language.compiler.ai_optimization import PantherAICompilerOptimizer, OptimizationNode, OptimizationUnit, AICostModel
from language.compiler.ai_optimization.passes import ConstantFoldingPass, DeadCodeEliminationPass, AgentHintPass
from language.compiler.integration.ai_optimizer_integration import optimize_with_ai_compiler

def test_constant_folding_pass():
    unit=OptimizationUnit('fold',[OptimizationNode('expr','+',{},[OptimizationNode('literal',2),OptimizationNode('literal',3)])])
    optimized, diagnostics=ConstantFoldingPass().run(unit)
    assert optimized.nodes[0].kind=='constant' and optimized.nodes[0].value==5
    assert diagnostics

def test_dead_code_elimination():
    unit=OptimizationUnit('dce',[OptimizationNode('expr','live'),OptimizationNode('dead','unreachable')])
    optimized, diagnostics=DeadCodeEliminationPass().run(unit)
    assert len(optimized.nodes)==1 and optimized.nodes[0].value=='live'
    assert diagnostics

def test_agent_hint_enrichment():
    unit=OptimizationUnit('agent',[OptimizationNode('agent_call','agent scout')])
    optimized, diagnostics=AgentHintPass().run(unit)
    assert optimized.nodes[0].metadata['ai_optimization_hint']
    assert optimized.nodes[0].metadata['safety']

def test_optimizer_source_report(tmp_path):
    result=PantherAICompilerOptimizer(report_dir=tmp_path).optimize_source('2 + 3\nagent scout\ndead unreachable', 'demo')
    assert result.success is True
    assert Path(result.report_path).exists()
    assert result.after_cost['node_count'] <= result.before_cost['node_count']

def test_integration_adapter():
    report=optimize_with_ai_compiler('workflow incident_response\nagent analyst', 'adapter_demo')
    assert report['success'] is True
    assert report['optimized_unit']['name']=='adapter_demo'

def test_negative_empty_source():
    with pytest.raises(ValueError): PantherAICompilerOptimizer().optimize_source('   ')

def test_cost_model_rejects_invalid_unit():
    with pytest.raises(ValueError): AICostModel().estimate(OptimizationUnit('', []))
