from compiler.ast import (
    BlockNode,
    EnumDeclaration,
    FieldDef,
    MemberExpression,
    StructDeclaration,
    TraitDeclaration,
    TraitMethodDef,
)
from compiler.runtime import execute_source


def test_field_def_ast():
    f = FieldDef(name="age")
    assert f.name == "age"
    assert f.children() == ()


def test_struct_declaration_ast():
    s = StructDeclaration(name="User", fields=(
        FieldDef(name="name"),
        FieldDef(name="age"),
    ))
    assert s.name == "User"
    assert len(s.fields) == 2
    assert s.children() == (s.fields[0], s.fields[1])


def test_struct_declaration_no_fields():
    s = StructDeclaration(name="Empty")
    assert s.fields == ()


def test_enum_declaration_ast():
    e = EnumDeclaration(name="Color", variants=("Red", "Green", "Blue"))
    assert e.name == "Color"
    assert e.variants == ("Red", "Green", "Blue")


def test_enum_declaration_no_variants():
    e = EnumDeclaration(name="Empty")
    assert e.variants == ()


def test_trait_method_def_ast():
    m = TraitMethodDef(name="greet", params=("self", "name"))
    assert m.name == "greet"
    assert m.params == ("self", "name")
    assert m.children() == ()


def test_trait_declaration_ast():
    t = TraitDeclaration(name="Greeter", methods=(
        TraitMethodDef(name="greet", params=("self",)),
        TraitMethodDef(name="bye", params=("self",)),
    ))
    assert t.name == "Greeter"
    assert len(t.methods) == 2


def test_parse_struct_no_fields():
    source = '''
panther main {
    struct Empty { }
    print("ok");
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ok"]


def test_parse_struct_with_fields():
    source = '''
panther main {
    struct User {
        name
        age
    }
    let u = User("Alice", 30);
    print(u.name);
    print(u.age);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["Alice", "30"]


def test_struct_member_expression():
    source = '''
panther main {
    struct Point {
        x
        y
    }
    let p = Point(10, 20);
    print(p.x);
    print(p.y);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["10", "20"]


def test_parse_enum():
    source = '''
panther main {
    enum Color {
        Red
        Green
        Blue
    }
    print("defined");
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["defined"]


def test_parse_trait():
    source = '''
panther main {
    trait Greeter {
        fn greet(self);
    }
    print("defined");
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["defined"]


def test_trait_with_multiple_methods():
    source = '''
panther main {
    trait Animal {
        fn speak(self);
        fn move(self);
    }
    print("ok");
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["ok"]





def test_struct_in_expression():
    source = '''
panther main {
    struct Pair {
        first
        second
    }
    let p = Pair(1, 2);
    let sum = p.first + p.second;
    print(sum);
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["3"]


def test_member_expression_ast():
    m = MemberExpression(
        object=StructDeclaration(name="Point"),
        property="x",
    )
    assert m.object is not None
    assert m.property == "x"
