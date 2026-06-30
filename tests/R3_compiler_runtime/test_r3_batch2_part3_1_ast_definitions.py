from compiler.ast import (
    ASTVisitor, BinaryExpression, BlockNode, MainBlockNode,
    NumberLiteral, PrintStatement, ProgramNode, SourceLocation,
    StringLiteral, ast_to_dict,
)


def test_create_hello_world_ast():
    expr = StringLiteral(value="Hello World")
    stmt = PrintStatement(expression=expr)
    block = BlockNode(statements=(stmt,))
    main = MainBlockNode(body=block)
    program = ProgramNode(body=(main,))
    assert program.children() == (main,)
    assert main.children() == (block,)
    assert block.children() == (stmt,)
    assert stmt.children() == (expr,)


def test_source_location_serializes():
    loc = SourceLocation(line=2, column=5, index=12)
    node = StringLiteral(value="x", location=loc)
    data = ast_to_dict(node)
    assert data["type"] == "StringLiteral"
    assert data["location"]["line"] == 2
    assert data["value"] == "x"


def test_binary_expression_children_and_serialization():
    expr = BinaryExpression(left=NumberLiteral(value=1), operator="+", right=NumberLiteral(value=2))
    assert len(expr.children()) == 2
    data = ast_to_dict(expr)
    assert data["type"] == "BinaryExpression"
    assert data["operator"] == "+"
    assert data["left"]["value"] == 1
    assert data["right"]["value"] == 2


def test_visitor_generic_traversal():
    class CountingVisitor(ASTVisitor):
        def __init__(self):
            self.count = 0
        def generic_visit(self, node):
            self.count += 1
            for child in node.children():
                self.visit(child)
            return self.count

    program = ProgramNode(body=(MainBlockNode(body=BlockNode(statements=(PrintStatement(expression=StringLiteral(value="Hello")),))),))
    visitor = CountingVisitor()
    visitor.visit(program)
    assert visitor.count == 5


def test_ast_nodes_are_comparable():
    assert StringLiteral(value="same") == StringLiteral(value="same")
    assert StringLiteral(value="same") != StringLiteral(value="different")
