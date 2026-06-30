def deny_by_default():
    return True

def require_capability(name, allowed):
    if name not in allowed:
        raise PermissionError(f"Capability denied: {name}")
    return True
