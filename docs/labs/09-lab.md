# Lab 09: Web Platform

## Objectives
- Create a web server using the `web { }` block
- Define GET routes with `route GET` syntax
- Define POST routes that accept and echo JSON
- Use route parameters for dynamic responses

## Theory

PantherLang's web platform uses a `web { }` block alongside `panther main { }`:

```panther
panther main {
    // startup logic
}

web {
    route GET "/path" {
        return "response";
    }
}
```

- Routes return string or object responses
- Route params use `:param` syntax in the path
- The server starts on `http://0.0.0.0:8080`
- Run with `panther run --serve file.pan`

## Exercises

### Exercise 1: Three Routes
**Task**: Create a `web` block with three GET routes: `"/"` returns `"Home"`, `"/about"` returns `{"service": "PantherWeb", "version": 1}`, and `"/health"` returns `{"status": "ok"}`.
**Hint**: Use `route GET "/" { return "..."; }`. Object literals work as JSON responses.
**Verify**: Run `python -m cli.panther_cli run --serve docs/labs/solutions/09-lab.pan`

### Exercise 2: Route Parameters
**Task**: Add a route `GET "/hello/:name"` that returns `"Hello, :name!"` where `:name` is replaced by the route parameter.
**Hint**: Access the route param as a variable named `name` in the route body. Use string concatenation with `+`.
**Verify**: Visit `http://localhost:8080/hello/Panther` to test.

### Exercise 3: POST Echo
**Task**: Add a `POST "/echo"` route that returns the string `"Received: "` followed by the request body.
**Hint**: Use `route POST "/echo"`. Access the body via a `body` variable.
**Verify**: Run `curl -X POST -d '{"test": "data"}' http://localhost:8080/echo`

## Summary
You created a PantherLang web server with GET and POST routes, route parameters, and JSON responses.

## Further Reading
- Book Chapter 09: Web Platform
- examples/hello_web/main.pan
