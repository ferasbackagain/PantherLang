from dataclasses import dataclass

@dataclass
class Task:
    name: str
    action: str

class Scheduler:
    def __init__(self):
        self.tasks=[]

    def add(self,name,action):
        self.tasks.append(Task(name,action))

    def run(self):
        out=[]
        for t in self.tasks:
            out.append(f"executed:{t.name}:{t.action}")
        return out
