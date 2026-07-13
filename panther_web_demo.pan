panther main {
    print "PantherLang Web Application";
    print "Routes: GET /, GET /about, GET /api/status, GET /health, POST /api/echo, GET /hello/{name}";
    print "Press Ctrl+C to stop the server.";
}

web {
    route GET "/" {
        return "<!DOCTYPE html><html><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width,initial-scale=1'>"
            + "<title>PantherLang Web</title>"
            + "<style>"
            + "body{margin:0;background:#08111d;color:#eaf3ff;font-family:Arial,sans-serif}"
            + "nav{padding:20px 8%;background:#0d1b2a;border-bottom:1px solid #21364d}"
            + "nav a{color:#8ee3ff;text-decoration:none;margin-right:24px}"
            + ".hero{padding:90px 8%;text-align:center}"
            + ".badge{display:inline-block;padding:8px 14px;border:1px solid #35d07f;border-radius:30px;color:#35d07f}"
            + ".hero h1{font-size:58px;margin:25px 0 10px}"
            + ".hero p{font-size:20px;color:#a9bed3}"
            + ".grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:18px;padding:20px 8% 80px}"
            + ".card{background:#102237;border:1px solid #213b57;border-radius:14px;padding:24px}"
            + ".card h3{color:#8ee3ff}"
            + "footer{text-align:center;padding:35px;color:#6f879f}"
            + "</style></head><body>"
            + "<nav><strong>PantherLang</strong><span style='float:right'><a href='/'>Home</a><a href='/about'>About</a><a href='/api/status'>API Status</a><a href='/health'>Health</a></span></nav>"
            + "<section class='hero'><span class='badge'>PantherLang v1.1.9</span>"
            + "<h1>Build Anything. In Panther.</h1>"
            + "<p>A real web page served by the PantherLang Web Runtime.</p>"
            + "<p>Web Engine: Running</p>"
            + "<p>Server Address: http://127.0.0.1:8080</p>"
            + "<p>Health Status: <a href='/health'>healthy</a></p>"
            + "</section>"
            + "<section class='grid'>"
            + "<div class='card'><h3>Independent Language</h3><p>Parser, semantic analysis, runtime, package system and standard library.</p></div>"
            + "<div class='card'><h3>Standard Library 2.0</h3><p>Organized packages for web, HTTP, database, networking, security, AI and more.</p></div>"
            + "<div class='card'><h3>Web Runtime</h3><p>Real GET/POST routing, HTML, JSON, path parameters and query parameters.</p></div>"
            + "<div class='card'><h3>Developer Tooling</h3><p>CLI, VS Code extension, diagnostics, examples and automated regression tests.</p></div>"
            + "</section>"
            + "<footer>Founder: Feras Khatib  — PantherLang</footer>"
            + "</body></html>";
    }

    route GET "/about" {
        return "<!DOCTYPE html><html><head><title>About PantherLang</title>"
            + "<style>body{background:#08111d;color:white;font-family:Arial;padding:60px;line-height:1.7}"
            + "a{color:#8ee3ff}.box{max-width:850px;margin:auto;background:#102237;padding:40px;border-radius:15px;border:1px solid #27425e}</style>"
            + "</head><body>"
            + "<div class='box'><h1>About PantherLang</h1>"
            + "<p>PantherLang is an independent programming-language project designed for modern software engineering, AI, cybersecurity, web, networking and data systems.</p>"
            + "<p>Founded by Feras Khatib. This page was returned from a real PantherLang web route.</p>"
            + "<a href='/'>Return home</a></div>"
            + "</body></html>";
    }

    route GET "/api/status" {
        return {
            ok: true,
            language: "PantherLang",
            version: "1.1.9",
            engine: "web",
            status: "running"
        };
    }

    route GET "/health" {
        return {status: "healthy"};
    }

    route GET "/hello/{name}" {
        return {
            message: "Hello from PantherLang",
            visitor: name
        };
    }

    route POST "/api/echo" {
        return {echo: "received", ok: true};
    }
}
