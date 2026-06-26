from dataclasses import dataclass, field

@dataclass
class Node:
    kind:str

@dataclass
class Program(Node):
    children:list = field(default_factory=list)

@dataclass
class Model(Node):
    name:str=""
    fields:list = field(default_factory=list)

@dataclass
class Field(Node):
    name:str=""
    type_name:str=""
