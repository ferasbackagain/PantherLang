from compiler.security.analyzer import SecurityAnalyzer


def test_security_analyzer_empty_program():
    from compiler.ast.program import ProgramNode
    from compiler.ast import BlockNode
    analyzer = SecurityAnalyzer()
    program = ProgramNode(body=[BlockNode(statements=[])])
    diags = analyzer.analyze(program)
    assert len(diags) == 0


def test_security_analyzer_hardcoded_secret():
    from compiler.ast import StringLiteral, VariableDeclaration
    from compiler.ast.program import ProgramNode
    from compiler.ast import BlockNode
    stmt = VariableDeclaration(
        name="api_key",
        initializer=StringLiteral(value="sk-12345678901234567890"),
    )
    program = ProgramNode(body=[BlockNode(statements=[stmt])])
    analyzer = SecurityAnalyzer()
    diags = analyzer.analyze(program)
    codes = [d.code for d in diags]
    assert "S005" in codes or "S001" in codes


def test_security_analyzer_env_var_not_secret():
    from compiler.ast import StringLiteral, VariableDeclaration
    from compiler.ast.program import ProgramNode
    from compiler.ast import BlockNode
    stmt = VariableDeclaration(
        name="api_key",
        initializer=StringLiteral(value="$ENV_VAR"),
    )
    program = ProgramNode(body=[BlockNode(statements=[stmt])])
    analyzer = SecurityAnalyzer()
    diags = analyzer.analyze(program)
    s001 = [d for d in diags if d.code == "S001"]
    assert len(s001) == 0


def test_security_analyzer_dangerous_function_call():
    from compiler.ast import CallExpression, IdentifierExpression
    from compiler.ast import ExpressionStatement, BlockNode
    from compiler.ast.program import ProgramNode
    expr = CallExpression(
        callee=IdentifierExpression(name="exec"),
        arguments=[],
    )
    stmt = ExpressionStatement(expression=expr)
    program = ProgramNode(body=[BlockNode(statements=[stmt])])
    analyzer = SecurityAnalyzer()
    diags = analyzer.analyze(program)
    codes = [d.code for d in diags]
    assert "S003" in codes


def test_security_analyzer_dangerous_string():
    from compiler.ast import PrintStatement, StringLiteral, BlockNode
    from compiler.ast.program import ProgramNode
    stmt = PrintStatement(expression=StringLiteral(value="run: rm -rf /"))
    program = ProgramNode(body=[BlockNode(statements=[stmt])])
    analyzer = SecurityAnalyzer()
    diags = analyzer.analyze(program)
    codes = [d.code for d in diags]
    assert "S004" in codes


def test_security_analyzer_clean_program():
    from compiler.ast import NumberLiteral, VariableDeclaration, BlockNode, PrintStatement
    from compiler.ast.program import ProgramNode
    decl = VariableDeclaration(name="x", initializer=NumberLiteral(value=42))
    print_stmt = PrintStatement(expression=NumberLiteral(value=42))
    program = ProgramNode(body=[BlockNode(statements=[decl, print_stmt])])
    analyzer = SecurityAnalyzer()
    diags = analyzer.analyze(program)
    assert len(diags) == 0
