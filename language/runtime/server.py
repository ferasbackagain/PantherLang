from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse
import json
from runtime.data_store import InMemoryDataStore

def run_server(semantic, host="127.0.0.1"):
    port = semantic.deploy.get("port", 7777)
    store = InMemoryDataStore(semantic)

    class Handler(BaseHTTPRequestHandler):
        def _json(self, status, payload):
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(payload, indent=2).encode("utf-8"))

        def _html(self, status, html):
            self.send_response(status)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(html.encode("utf-8"))

        def do_GET(self):
            parsed = urlparse(self.path)

            if parsed.path == "/__panther/semantic":
                self._json(200, semantic.to_dict())
                return

            if parsed.path == "/__panther/ir":
                from compiler.core.ir import semantic_to_ir
                self._json(200, semantic_to_ir(semantic))
                return

            for api in semantic.apis:
                if api.method == "GET" and parsed.path == api.path:
                    if api.action == "list" and api.model:
                        self._json(200, {"panther": True, "model": api.model, "data": store.list(api.model)})
                        return

            for page in semantic.pages:
                if parsed.path == "/" or parsed.path.lower() == "/" + page.name.lower():
                    self._html(200, page_html(semantic, page, store))
                    return

            self._html(200, dashboard_html(semantic))

        def do_POST(self):
            parsed = urlparse(self.path)
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length).decode("utf-8") if length else "{}"

            try:
                payload = json.loads(body or "{}")
            except json.JSONDecodeError:
                self._json(400, {"error": "Invalid JSON"})
                return

            for api in semantic.apis:
                if api.method == "POST" and parsed.path == api.path:
                    if api.action == "create" and api.model:
                        try:
                            record = store.create(api.model, payload)
                        except ValueError as e:
                            self._json(400, {"error": str(e)})
                            return
                        self._json(201, {"panther": True, "model": api.model, "record": record})
                        return

            self._json(404, {"error": "No matching Panther API endpoint"})

        def log_message(self, format, *args):
            print("PantherRuntime:", format % args)

    print(f"🐾 Panther Runtime v0.5 running {semantic.app_name}")
    print(f"🌐 Open: http://{host}:{port}")
    print(f"🧠 Semantic: http://{host}:{port}/__panther/semantic")
    print(f"🧩 IR: http://{host}:{port}/__panther/ir")
    HTTPServer((host, port), Handler).serve_forever()

def base_css():
    return """
    body{margin:0;font-family:Arial,sans-serif;background:#060914;color:#f8fafc}
    .hero{padding:55px;background:linear-gradient(135deg,#0f172a,#111827);border-bottom:1px solid #1f2937}
    .badge{color:#22c55e;font-weight:bold}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:18px;padding:30px 60px}
    .card{background:#111827;border:1px solid #243244;border-radius:18px;padding:22px}
    code,a{color:#93c5fd}
    table{border-collapse:collapse;width:100%;margin-top:20px}
    th,td{border:1px solid #243244;padding:10px;text-align:left}
    th{background:#111827}
    .section{padding:30px 60px}
    """

def dashboard_html(semantic):
    def join(items):
        return ", ".join(items) if items else "None"
    cards = [
        ("Data Models", join([m.name for m in semantic.data_models])),
        ("APIs", join([f"{a.method} {a.path}" for a in semantic.apis])),
        ("UI Pages", join([p.name for p in semantic.pages])),
        ("Workflows", join(semantic.workflows)),
        ("Agents", join(semantic.agents)),
        ("Devices", join(semantic.devices)),
        ("Tasks", join(semantic.tasks)),
        ("Targets", join(semantic.targets)),
    ]
    card_html = "\n".join(f'<div class="card"><h2>{t}</h2><p>{v}</p></div>' for t, v in cards)
    first_page = semantic.pages[0].name if semantic.pages else ""
    page_link = f'<p>UI page: <a href="/{first_page}">/{first_page}</a></p>' if first_page else ""
    return f"""<!doctype html><html><head><meta charset="utf-8"/><title>{semantic.app_name}</title><style>{base_css()}</style></head>
<body><div class="hero"><div class="badge">🐾 PantherLang Runtime v0.5</div><h1>{semantic.app_name}</h1>
<p>{semantic.description or 'Executable PantherLang system.'}</p>
<p><a href="/__panther/semantic">Semantic JSON</a> | <a href="/__panther/ir">IR JSON</a></p>{page_link}</div>
<div class="grid">{card_html}</div></body></html>"""

def page_html(semantic, page, store):
    sections = []
    for model_name in page.tables:
        records = store.list(model_name)
        model = next((m for m in semantic.data_models if m.name == model_name), None)
        fields = model.fields if model else []
        if records:
            rows = []
            for rec in records:
                cells = "".join(f"<td>{rec.get(f.name, '')}</td>" for f in fields)
                rows.append(f"<tr>{cells}</tr>")
            body = "\n".join(rows)
        else:
            body = f'<tr><td colspan="{max(len(fields),1)}">No records yet. Use POST {api_path_for_model(semantic, model_name)} to create one.</td></tr>'
        headers = "".join(f"<th>{f.name}</th>" for f in fields) or "<th>Empty</th>"
        sections.append(f"<div class='section'><h2>{model_name}</h2><table><thead><tr>{headers}</tr></thead><tbody>{body}</tbody></table></div>")
    section_html = "\n".join(sections)
    return f"""<!doctype html><html><head><meta charset="utf-8"/><title>{page.title or page.name}</title><style>{base_css()}</style></head>
<body><div class="hero"><div class="badge">🐾 PantherLang UI v0.5</div><h1>{page.title or page.name}</h1><p>{page.hero}</p><p><a href="/">Dashboard</a></p></div>{section_html}</body></html>"""

def api_path_for_model(semantic, model_name):
    for api in semantic.apis:
        if api.model == model_name and api.method == "POST":
            return api.path
    return ""
