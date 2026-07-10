#!/usr/bin/env python3
from __future__ import annotations
import json

class Optimizer:
    def optimize(self, ir):
        optimized=[]
        for node in ir:
            if node.get("op")=="ADD" and node.get("lhs")==0:
                optimized.append({"op":"MOV","value":node["rhs"]})
            else:
                optimized.append(node)
        return optimized

if __name__=="__main__":
    sample=[{"op":"ADD","lhs":0,"rhs":"x"},{"op":"PRINT","value":"done"}]
    print(json.dumps({"ok":True,"phase":"9.3","optimized":Optimizer().optimize(sample)},indent=2))
