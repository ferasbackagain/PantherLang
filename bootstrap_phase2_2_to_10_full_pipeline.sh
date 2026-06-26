#!/usr/bin/env bash
set -e

echo "🐾 PantherLang Phase 2.2–2.10 — Full Compiler Pipeline Bootstrap"
echo "Root: $(pwd)"

mkdir -p \
  architecture/phase2 \
  language/compiler/ast \
  language/compiler/parsers \
  language/compiler/integration \
  language/examples \
  language/tests \
  scripts \
  docs

# =========================
# Phase 2.2 — Real AST Builder
# =========================

cat > architecture/phase2/PHASE_2_2_TO_2_10.md <<'EOF'
# PantherLang Phase 2.2–2.10

## Goal
Build the first end-to-end PantherLang source compiler pipeline.

## Pipeline
.panther Source
→ Lexer
→ Token Stream
→ AST Builder
→ App Parser
→ Model Parser
→ API Parser
→ Page Parser
→ Agent Parser
→ Semantic Integration
→ IR Integration
→ Code Generator

## Modules
- 2.2 Real AST Builder
- 2.3 Model Parser
- 2.4 App Parser
- 2.5 API Parser
- 2.6 Page Parser
- 2.7 Agent Parser
- 2.8 Semantic Integration
- 2.9 IR Integration
- 2.10 End-to-End Compiler
EOF

cat > language/compiler/ast/nodes.py <<'EOF'
from dataclasses import dataclass, field
from typing import List


@dataclass
class ASTField:
    name: str
    type_name: str
    required: bool = False
    default: str = ""


@dataclass
class ASTModel:
    name: str
    fields: List[ASTField] = field(default_factory=list)


@dataclass
class ASTApp:
    name: str
    version: str = "0.5"


@dataclass
class ASTApi:
    method: str
    path: str


@dataclass
class ASTPage:
    name: str
    title: str = ""
    table: str = ""


@dataclass
class ASTAgent:
    name: str
    purpose: str = ""
    memory: str = "none"
    tools: List[str] = field(default_factory=list)


@dataclass
class ASTProgram:
    app: ASTApp | None = None
    models: List[ASTModel] = field(default_factory=list)
    apis: List[ASTApi] = field(default_factory=list)
    pages: List[ASTPage] = field(default_factory=list)
    agents: List[ASTAgent] = field(default_factory=list)
EOF

cat > language/compiler/ast/__init__.py <<'EOF'
from .nodes import ASTProgram, ASTApp, ASTModel, ASTField, ASTApi, ASTPage, ASTAgent
EOF

# =========================
# Shared parsing utilities
# =========================

cat > language/compiler/parsers/block_utils.py <<'EOF'
import re


def extract_named_blocks(source, keyword):
    pattern = re.compile(rf"{keyword}\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\{{(.*?)\\}}", re.S)
    return pattern.findall(source)


def extract_app(source):
    m = re.search(r"app\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*\\{(.*?)\\}", source, re.S)
    return m.groups() if m else None


def extract_api(source):
    pattern = re.compile(r"api\\s+(GET|POST|PUT|PATCH|DELETE)\\s+([^\\s\\{]+)\\s*\\{(.*?)\\}", re.S)
    return pattern.findall(source)


def clean_lines(block):
    return [line.strip() for line in block.splitlines() if line.strip()]
EOF

# =========================
# Phase 2.3 — Model Parser
# =========================

cat > language/compiler/parsers/model_parser.py <<'EOF'
from language.compiler.ast import ASTModel, ASTField
from .block_utils import extract_named_blocks, clean_lines


class ModelParser:
    def parse(self, source):
        models = []
        for name, body in extract_named_blocks(source, "model"):
            model = ASTModel(name=name)
            for line in clean_lines(body):
                if ":" not in line:
                    continue
                left, right = line.split(":", 1)
                field_name = left.strip()
                parts = right.strip().split()
                type_name = parts[0] if parts else "any"
                required = "required" in parts
                default = ""
                if "=" in line:
                    default = line.split("=", 1)[1].strip()
                model.fields.append(ASTField(field_name, type_name, required, default))
            models.append(model)
        return models
EOF

# =========================
# Phase 2.4 — App Parser
# =========================

cat > language/compiler/parsers/app_parser.py <<'EOF'
import re
from language.compiler.ast import ASTApp
from .block_utils import extract_app


class AppParser:
    def parse(self, source):
        found = extract_app(source)
        if not found:
            return None
        name, body = found
        version = "0.5"
        m = re.search(r'version\\s+"([^"]+)"', body)
        if m:
            version = m.group(1)
        return ASTApp(name=name, version=version)
EOF

# =========================
# Phase 2.5 — API Parser
# =========================

cat > language/compiler/parsers/api_parser.py <<'EOF'
from language.compiler.ast import ASTApi
from .block_utils import extract_api


class ApiParser:
    def parse(self, source):
        return [ASTApi(method=method, path=path) for method, path, body in extract_api(source)]
EOF

# =========================
# Phase 2.6 — Page Parser
# =========================

cat > language/compiler/parsers/page_parser.py <<'EOF'
import re
from language.compiler.ast import ASTPage
from .block_utils import extract_named_blocks


class PageParser:
    def parse(self, source):
        pages = []
        for name, body in extract_named_blocks(source, "page"):
            title = ""
            table = ""
            mt = re.search(r'title\\s+"([^"]+)"', body)
            if mt:
                title = mt.group(1)
            mb = re.search(r'table\\s+([A-Za-z_][A-Za-z0-9_]*)', body)
            if mb:
                table = mb.group(1)
            pages.append(ASTPage(name=name, title=title, table=table))
        return pages
EOF

# =========================
# Phase 2.7 — Agent Parser
# =========================

cat > language/compiler/parsers/agent_parser.py <<'EOF'
import re
from language.compiler.ast import ASTAgent
from .block_utils import extract_named_blocks


class AgentParser:
    def parse(self, source):
        agents = []
        for name, body in extract_named_blocks(source, "agent"):
            purpose = ""
            memory = "none"
            tools = []
            mp = re.search(r'purpose\\s+"([^"]+)"', body)
            if mp:
                purpose = mp.group(1)
            mm = re.search(r'memory\\s+([A-Za-z_][A-Za-z0-9_]*)', body)
            if mm:
                memory = mm.group(1)
            mt = re.search(r'tools\\s+([^\\n]+)', body)
            if mt:
                tools = [x.strip() for x in mt.group(1).split(",") if x.strip()]
            agents.append(ASTAgent(name=name, purpose=purpose, memory=memory, tools=tools))
        return agents
EOF

cat > language/compiler/parsers/__init__.py <<'EOF'
from .app_parser import AppParser
from .model_parser import ModelParser
from .api_parser import ApiParser
from .page_parser import PageParser
from .agent_parser import AgentParser
EOF

# =========================
# Phase 2.2 — AST Builder
# =========================

cat > language/compiler/ast/ast_builder.py <<'EOF'
from language.compiler.ast import ASTProgram
from language.compiler.parsers import AppParser, ModelParser, ApiParser, PageParser, AgentParser


class RealASTBuilder:
    def build(self, source):
        return ASTProgram(
            app=AppParser().parse(source),
            models=ModelParser().parse(source),
            apis=ApiParser().parse(source),
            pages=PageParser().parse(source),
            agents=AgentParser().parse(source),
        )
EOF

# =========================
# Phase 2.8 — Semantic Integration
# =========================

cat > language/compiler/integration/semantic_integration.py <<'EOF'
from language.compiler.core.semantic_engine import SemanticEngine
from language.models.core_models import PantherModel, PantherField


class Phase2SemanticIntegration:
    def ast_model_to_core_model(self, ast_model):
        return PantherModel(
            name=ast_model.name,
            fields=[
                PantherField(
                    name=f.name,
                    type_name=f.type_name,
                    required=f.required,
                    default=f.default or None,
                )
                for f in ast_model.fields
            ],
        )

    def analyze(self, ast_program):
        engine = SemanticEngine()
        ok = True
        core_models = []
        for ast_model in ast_program.models:
            core_model = self.ast_model_to_core_model(ast_model)
            core_models.append(core_model)
            if not engine.analyze_model(core_model):
                ok = False
        return ok, core_models
EOF

# =========================
# Phase 2.9 — IR Integration
# =========================

cat > language/compiler/integration/ir_integration.py <<'EOF'
from language.compiler.core.ir_builder import IRBuilder


class Phase2IRIntegration:
    def build_ir(self, core_models, app_name="PantherApp"):
        return IRBuilder().build_program_from_models(core_models, name=app_name)
EOF

# =========================
# Phase 2.10 — End-to-End Compiler
# =========================

cat > language/compiler/integration/e2e_compiler.py <<'EOF'
from pathlib import Path
from language.compiler.ast.ast_builder import RealASTBuilder
from language.compiler.integration.semantic_integration import Phase2SemanticIntegration
from language.compiler.integration.ir_integration import Phase2IRIntegration
from language.compiler.core.codegen import PythonCodeGenerator


class PantherEndToEndCompiler:
    def compile_source(self, source):
        ast = RealASTBuilder().build(source)
        app_name = ast.app.name if ast.app else "PantherApp"

        semantic_ok, core_models = Phase2SemanticIntegration().analyze(ast)
        if not semantic_ok:
            raise ValueError("Semantic analysis failed")

        ir = Phase2IRIntegration().build_ir(core_models, app_name=app_name)
        code = PythonCodeGenerator().generate(ir)

        return {
            "ast": ast,
            "ir": ir,
            "code": code,
        }

    def compile_file(self, path):
        source = Path(path).read_text()
        return self.compile_source(source)
EOF

cat > language/compiler/integration/__init__.py <<'EOF'
from .e2e_compiler import PantherEndToEndCompiler
EOF

# =========================
# Example
# =========================

cat > language/examples/phase2_full_system.panther <<'EOF'
app PantherStore {
    version "0.5"
}

model Product {
    id: uuid
    title: string required
    price: decimal required
    stock: int = 0
}

model User {
    id: uuid
    name: string required
    email: string required
}

api GET /products {
    public
    return Product.all()
}

page Products {
    title "Products"
    table Product
}

agent InventoryAI {
    purpose "Monitor inventory"
    tools data, api
    memory scoped
}
EOF

# =========================
# Tests
# =========================

cat > language/tests/test_phase2_2_to_10.py <<'EOF'
from language.compiler.ast.ast_builder import RealASTBuilder
from language.compiler.integration import PantherEndToEndCompiler

source = open("language/examples/phase2_full_system.panther").read()

ast = RealASTBuilder().build(source)

assert ast.app.name == "PantherStore"
assert ast.app.version == "0.5"
assert len(ast.models) == 2
assert ast.models[0].name == "Product"
assert ast.models[0].fields[1].name == "title"
assert ast.models[0].fields[1].required is True
assert ast.apis[0].method == "GET"
assert ast.apis[0].path == "/products"
assert ast.pages[0].name == "Products"
assert ast.pages[0].table == "Product"
assert ast.agents[0].name == "InventoryAI"
assert ast.agents[0].memory == "scoped"

compiled = PantherEndToEndCompiler().compile_source(source)

assert compiled["ir"].to_dict()["name"] == "PantherStore"
assert "PantherStore" in compiled["code"]
assert "Product" in compiled["code"]
assert "User" in compiled["code"]

print("✅ Phase 2.2–2.10 full compiler pipeline tests passed.")
EOF

cat > docs/PHASE_2_STATUS.md <<'EOF'
# PantherLang Phase 2 Status

## Completed
- 2.1 Real Source Pipeline
- 2.2 Real AST Builder
- 2.3 Model Parser
- 2.4 App Parser
- 2.5 API Parser
- 2.6 Page Parser
- 2.7 Agent Parser
- 2.8 Semantic Integration
- 2.9 IR Integration
- 2.10 End-to-End Compiler

## Result
PantherLang can now compile a real `.panther` source file through AST, semantic validation, IR, and code generation.

## Next
Phase 3 — Runtime Execution + Real CLI Integration
EOF

cat > scripts/verify_phase2_full.sh <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase2_2_to_10.py
echo "✅ PantherLang Phase 2.2–2.10 full verification complete."
EOF

chmod +x scripts/verify_phase2_full.sh

PYTHONPATH="$PWD:$PWD/language" python3 language/tests/test_phase2_2_to_10.py

echo "--------------------------------"
echo "✅ PantherLang Phase 2.2–2.10 installed successfully."
echo "Run anytime: bash scripts/verify_phase2_full.sh"
echo "Next: Phase 3 — Runtime Execution + Real CLI Integration"
echo "--------------------------------"
