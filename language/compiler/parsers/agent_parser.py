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
            mp = re.search(r'purpose\s+"([^"]+)"', body)
            if mp:
                purpose = mp.group(1)
            mm = re.search(r'memory\s+([A-Za-z_][A-Za-z0-9_]*)', body)
            if mm:
                memory = mm.group(1)
            mt = re.search(r'tools\s+([^\n]+)', body)
            if mt:
                tools = [x.strip() for x in mt.group(1).split(",") if x.strip()]
            agents.append(ASTAgent(name=name, purpose=purpose, memory=memory, tools=tools))
        return agents
