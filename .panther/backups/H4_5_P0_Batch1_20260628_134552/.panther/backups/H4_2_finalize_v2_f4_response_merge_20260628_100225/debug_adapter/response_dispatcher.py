from .events import dap_response


class ResponseDispatcher:
    def success(self, command, request_seq=None, body=None):
        return dap_response(command, request_seq=request_seq, success=True, body=body or {})

    def error(self, command, request_seq=None, message="request failed", body=None):
        return dap_response(command, request_seq=request_seq, success=False, body=body or {}, message=message)

    def normalize(self, message, request_seq=None, command=None):
        if not isinstance(message, dict):
            return self.success(command, request_seq=request_seq, body={"value": message})

        message_type = message.get("type")
        if message_type == "event":
            message.setdefault("request_seq", request_seq)
            message.setdefault("sourceCommand", command)
            return message

        if message_type == "response":
            message.setdefault("request_seq", request_seq)
            message.setdefault("command", command)
            message.setdefault("success", True)
            return message

        return self.success(command, request_seq=request_seq, body=message)
