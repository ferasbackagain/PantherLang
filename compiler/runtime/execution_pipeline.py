from __future__ import annotations
from typing import Any
from compiler.ast import AiBlockNode, ApiBlockNode, WebBlockNode
from compiler.lexer import lex_source
from compiler.parser import ProgramParser
from compiler.parser.token_stream import TokenStream
from compiler.stdlib.selfhost import apply_selfhosted_stdlib
from compiler.semantic import analyze as semantic_analyze

from .statement_executor import ExecutionResult, StatementExecutor
from .variable_environment import VariableEnvironment

# Holds the last HttpServer created by execute_source for web/api blocks.
# Used by run_source to start the server.
_last_web_server: Any = None


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
    program = parse_result.node

    # Auto-provide HttpServer for web/api blocks so routes can register
    has_web = any(isinstance(b, (WebBlockNode, ApiBlockNode)) for b in program.body)

    if has_web:
        from compiler.web import HttpServer
        server = HttpServer(host="127.0.0.1", port=8080)
        executor = StatementExecutor(env, http_server=server)
    else:
        executor = StatementExecutor(env)

    # Execute all blocks (registers routes for web blocks, runs main for panther blocks)
    for block in program.body:
        if hasattr(block, "body") and block.body is not None:
            result = executor.run(list(block.body.statements))
            if result.error is not None:
                return result
            if result.return_value is not None:
                return result

    if has_web:
        if not any(r.method == "GET" and r.path == "/health" for r in server.router.routes):
            server.router.add_route("GET", "/health", lambda **kwargs: {"status": "healthy"})
        global _last_web_server
        _last_web_server = server

    return ExecutionResult(captured_output=list(executor.output))


def _open_browser(url: str) -> None:
    import subprocess, shutil, warnings
    for cmd in ["xdg-open", "firefox", "sensible-browser", "open"]:
        exe = shutil.which(cmd)
        if exe:
            try:
                with warnings.catch_warnings():
                    warnings.simplefilter("ignore", ResourceWarning)
                    subprocess.Popen([exe, url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                return
            except Exception:
                continue


def run_source(source: str) -> ExecutionResult:
    """Execute source and run the web server if web/api blocks exist (blocks until shutdown)."""
    import signal

    global _last_web_server
    _last_web_server = None

    base_result = execute_source(source)
    if base_result.error is not None:
        return base_result

    server = _last_web_server
    if server is not None:
        if base_result.captured_output:
            for line in base_result.captured_output:
                print(line)
        url = f"http://127.0.0.1:{server.port}"
        print(f"Panther web server starting on {url}")
        route_count = len(server.router.routes)
        print(f"Registered routes: {route_count}")

        def _stop_server(signum: object, frame: object) -> None:
            if server._server is not None:
                server.stop()
            raise KeyboardInterrupt

        signal.signal(signal.SIGTERM, _stop_server)
        signal.signal(signal.SIGINT, _stop_server)

        server.start_background(enable_logging=False)

        if server._fatal_error:
            signal.signal(signal.SIGTERM, signal.SIG_DFL)
            signal.signal(signal.SIGINT, signal.SIG_DFL)
            print(f"ERROR: {server._fatal_error}")
            return ExecutionResult(error=str(server._fatal_error))

        if server.is_ready(timeout_ms=5000):
            print("Server ready — opening browser...")
            _open_browser(url)
        else:
            print("Warning: server not ready after 5s, still starting...")

        try:
            server.wait()
        except KeyboardInterrupt:
            if server._server is not None:
                server.stop()
        finally:
            signal.signal(signal.SIGTERM, signal.SIG_DFL)
            signal.signal(signal.SIGINT, signal.SIG_DFL)
            if server._server is not None:
                server.stop()
        _last_web_server = None
        return ExecutionResult()

    if base_result.captured_output:
        for line in base_result.captured_output:
            print(line)
    return base_result


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
