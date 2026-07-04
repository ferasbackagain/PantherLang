from compiler.runtime import execute_source


def test_object_literal_assignment_and_index_execution():
    source = '''
panther main {
    let user = { name: "Feras", role: "founder" };
    print user["name"];
    print user["role"];
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["Feras", "founder"]


def test_array_literal_assignment_and_index_execution():
    source = '''
panther main {
    let nums = [10, 20, 30];
    print nums[0];
    print nums[2];
}
'''
    result = execute_source(source)
    assert result.error is None
    assert result.captured_output == ["10", "30"]


def test_object_literal_return_from_web_route_parses():
    source = '''
web {
    route GET "/health" {
        return { status: "ok", service: "panther-web" };
    }
}
'''
    result = execute_source(source)
    assert result.error is None
