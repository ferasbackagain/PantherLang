from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class TypeBase:
    name: str = "unknown"

    def __str__(self) -> str:
        return self.name


IntType = TypeBase("int")
FloatType = TypeBase("float")
StringType = TypeBase("string")
BoolType = TypeBase("bool")
NullType = TypeBase("null")
AnyType = TypeBase("any")


_PRIMITIVE_TYPES = {IntType, FloatType, StringType, BoolType, NullType}
_NUMERIC_TYPES = {IntType, FloatType}


def is_assignable(value_type: TypeBase, target_type: TypeBase) -> bool:
    if target_type is AnyType:
        return True
    if value_type is target_type:
        return True
    if value_type is IntType and target_type is FloatType:
        return True
    return False


def get_common_type(left: TypeBase, right: TypeBase) -> TypeBase:
    if left is AnyType or right is AnyType:
        return AnyType
    if left is FloatType or right is FloatType:
        if left in _NUMERIC_TYPES and right in _NUMERIC_TYPES:
            return FloatType
    if left is right:
        return left
    return AnyType
