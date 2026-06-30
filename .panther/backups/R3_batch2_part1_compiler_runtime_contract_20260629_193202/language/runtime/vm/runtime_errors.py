class PantherRuntimeError(Exception):
    pass


class PantherTypeRuntimeError(PantherRuntimeError):
    pass


class PantherModuleRuntimeError(PantherRuntimeError):
    pass


class PantherPermissionRuntimeError(PantherRuntimeError):
    pass
