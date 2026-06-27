from dataclasses import dataclass, field

@dataclass
class RuntimeState:
    values: dict = field(default_factory=dict)

    def set(self,key,value):
        self.values[key]=value

    def get(self,key,default=None):
        return self.values.get(key,default)

class ContextEngine:
    def __init__(self):
        self.global_state=RuntimeState()
        self.agent_states={}

    def context(self,agent):
        if agent not in self.agent_states:
            self.agent_states[agent]=RuntimeState()
        return self.agent_states[agent]

    def sync(self,agent,key):
        self.context(agent).set(key,self.global_state.get(key))
