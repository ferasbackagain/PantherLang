class PantherExpressionError(Exception):
    pass

class ExpressionEngine:
    def __init__(self, symbols=None):
        self.symbols = symbols or {}

    def evaluate(self, expr):
        expr = expr.strip()
        if expr.startswith('"') and expr.endswith('"'):
            return expr.strip('"')
        if expr in self.symbols:
            return self.symbols[expr]
        try:
            return int(expr)
        except ValueError:
            return expr

def panther_format(value):
    if value is True:
        return "true"
    if value is False:
        return "false"
    return str(value)
