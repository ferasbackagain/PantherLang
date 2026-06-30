class AgentSpec:
    def __init__(self, name, purpose="", tools=None, memory="none"):
        self.name = name
        self.purpose = purpose
        self.tools = tools or []
        self.memory = memory

    def to_dict(self):
        return {
            "name": self.name,
            "purpose": self.purpose,
            "tools": self.tools,
            "memory": self.memory,
        }
