class HttpResponse:
    def __init__(self, status=200, body=None):
        self.status = status
        self.body = body or {}

    def to_dict(self):
        return {"status": self.status, "body": self.body}

def ok(body=None):
    return HttpResponse(200, body).to_dict()

def created(body=None):
    return HttpResponse(201, body).to_dict()

def error(message, status=400):
    return HttpResponse(status, {"error": message}).to_dict()
