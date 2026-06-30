import json


def ir_to_json(ir_program, indent=2):
    return json.dumps(ir_program.to_dict(), indent=indent)
