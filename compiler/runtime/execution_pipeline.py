from __future__ import annotations
from compiler.ast import AiBlockNode, ApiBlockNode, WebBlockNode
from compiler.lexer import lex_source
from compiler.parser import ProgramParser
from compiler.parser.token_stream import TokenStream
from compiler.stdlib.selfhost import apply_selfhosted_stdlib
from compiler.semantic import analyze as semantic_analyze

from .statement_executor import ExecutionResult, StatementExecutor
from .variable_environment import VariableEnvironment


def _check_semantics(parse_result, environment: VariableEnvironment | None = None) -> ExecutionResult | None:
    if parse_result.node is not None:
        # If environment is provided, skip strict semantic checking since env vars are defined at runtime
        if environment is not None:
            return None
        diagnostics = semantic_analyze(parse_result.node)
        errors = [d for d in diagnostics if d.code.startswith("E") or d.code.startswith("T")]
        if errors:
            msg = "; ".join(str(d) for d in errors)
            return ExecutionResult(error=f"Semantic error: {msg}")
    return None


def execute_source(source: str, environment: VariableEnvironment | None = None) -> ExecutionResult:
    source = apply_selfhosted_stdlib(source)
    tokens = lex_source(source)
    stream = TokenStream(tokens)
    parser = ProgramParser(stream)
    parse_result = parser.parse()
    if not parse_result.ok:
        msg = "; ".join(str(d) for d in parse_result.diagnostics)
        return ExecutionResult(error=f"Parse error: {msg}")

    sem_error = _check_semantics(parse_result, environment)
    if sem_error is not None:
        return sem_error

    env = environment or VariableEnvironment.create_default()
    executor = StatementExecutor(env)
    program = parse_result.node

    for block in program.body:
        if hasattr(block, "body") and block.body is not None:
            result = executor.run(list(block.body.statements))
            if result.error is not None:
                return result
            if result.return_value is not None:
                return result

    return ExecutionResult(captured_output=list(executor.output))


def serve_source(source: str, host: str = "0.0.0.0", port: int = 8080) -> ExecutionResult:
    source = apply_selfhosted_stdlib(source)
    tokens = lex_source(source)
    stream = TokenStream(tokens)
    parser = ProgramParser(stream)
    parse_result = parser.parse()
    if not parse_result.ok:
        msg = "; ".join(str(d) for d in parse_result.diagnostics)
        return ExecutionResult(error=f"Parse error: {msg}")

    sem_error = _check_semantics(parse_result, None)
    if sem_error is not None:
        return sem_error

    env = VariableEnvironment.create_default()
    program = parse_result.node

    has_web = any(isinstance(b, (WebBlockNode, ApiBlockNode)) for b in program.body)
    if not has_web:
        executor = StatementExecutor(env)
        for block in program.body:
            if hasattr(block, "body") and block.body is not None:
                result = executor.run(list(block.body.statements))
                if result.error is not None:
                    return result
                if result.return_value is not None:
                    return result
        return ExecutionResult(captured_output=list(executor.output))

    from compiler.web import HttpServer
    server = HttpServer(host=host, port=port)
    executor = StatementExecutor(env, http_server=server)

    for block in program.body:
        if hasattr(block, "body") and block.body is not None:
            result = executor.run(list(block.body.statements))
            if result.error is not None:
                return result
            if result.return_value is not None:
                return result

    if not any(r.method == "GET" and r.path == "/health" for r in server.router.routes):
        server.router.add_route("GET", "/health", lambda **kwargs: {"status": "ok", "service": "panther"})

    route_count = len(server.router.routes)
    print(f"Panther web server starting on http://{host}:{port}")
    print(f"Registered routes: {route_count}")
    try:
        server.start()
    except KeyboardInterrupt:
        print("Panther web server stopped")
    return ExecutionResult(captured_output=list(executor.output))
