from dataclasses import dataclass, field

@dataclass
class RuntimeNode:
    node_id: str
    status: str = "online"

@dataclass
class DistributedRuntime:
    nodes: dict = field(default_factory=dict)

    def register(self, node_id: str):
        self.nodes[node_id] = RuntimeNode(node_id)

    def broadcast(self, message: str):
        return {nid: f"{message}@{nid}" for nid in self.nodes}

    def node_count(self):
        return len(self.nodes)
