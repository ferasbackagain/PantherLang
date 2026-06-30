from dataclasses import dataclass

@dataclass(frozen=True)
class PantherType:
    name: str
    nullable: bool = False
    generic_args: tuple = ()

    def __str__(self):
        base = self.name
        if self.generic_args:
            base += "<" + ", ".join(str(arg) for arg in self.generic_args) + ">"
        if self.nullable:
            base += "?"
        return base

PRIMITIVE_TYPES = {"int","float","decimal","bool","string","char","bytes","uuid","date","time","datetime","duration","json","any","void"}
COLLECTION_TYPES = {"list","array","map","set","tuple"}
ADVANCED_TYPES = {"optional","result","future","stream"}
ALL_BUILTIN_TYPES = PRIMITIVE_TYPES | COLLECTION_TYPES | ADVANCED_TYPES

def is_builtin_type(type_name: str) -> bool:
    return type_name in ALL_BUILTIN_TYPES

def parse_type(type_name: str) -> PantherType:
    nullable = type_name.endswith("?")
    clean = type_name[:-1] if nullable else type_name
    return PantherType(name=clean, nullable=nullable)
