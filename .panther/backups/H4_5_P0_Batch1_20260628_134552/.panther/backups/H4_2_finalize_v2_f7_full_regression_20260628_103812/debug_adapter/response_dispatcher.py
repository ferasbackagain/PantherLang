from .response_merge import ResponseMergeEngine


class ResponseDispatcher:
    """Compatibility facade backed by the H4.2 F4 response merge engine."""

    def __init__(self, engine=None):
        self.engine = engine or ResponseMergeEngine()

    def success(self, command, request_seq=None, body=None):
        return self.engine.success(command, request_seq=request_seq, body=body or {})

    def error(self, command, request_seq=None, message="request failed", body=None):
        return self.engine.error(
            command,
            request_seq=request_seq,
            message=message,
            body=body or {},
        )

    def normalize(self, message, request_seq=None, command=None):
        return self.engine.normalize(
            message,
            request_seq=request_seq,
            command=command,
        )
