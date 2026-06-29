from dataclasses import dataclass

@dataclass
class Plugin:
    name:str
    version:str
    enabled:bool=True

class PluginManager:
    def __init__(self):
        self.plugins={}

    def register(self,name,version="1.0"):
        self.plugins[name]=Plugin(name,version)

    def load(self,name):
        if name not in self.plugins:
            raise KeyError(name)
        return self.plugins[name]

    def list(self):
        return list(self.plugins.values())
