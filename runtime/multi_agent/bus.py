from dataclasses import dataclass

@dataclass
class Message:
    sender:str
    receiver:str
    payload:str

class AgentBus:
    def __init__(self):
        self.messages=[]

    def send(self,sender,receiver,payload):
        self.messages.append(Message(sender,receiver,payload))

    def inbox(self,receiver):
        return [m for m in self.messages if m.receiver==receiver]

class Agent:
    def __init__(self,name,bus):
        self.name=name
        self.bus=bus

    def send(self,to,msg):
        self.bus.send(self.name,to,msg)
