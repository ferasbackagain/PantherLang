from language.compiler.ast import ASTModel, ASTField
from .block_utils import extract_named_blocks, clean_lines


class ModelParser:
    def parse(self, source):
        models = []
        for name, body in extract_named_blocks(source, "model"):
            model = ASTModel(name=name)
            for line in clean_lines(body):
                if ":" not in line:
                    continue
                left, right = line.split(":", 1)
                field_name = left.strip()
                parts = right.strip().split()
                type_name = parts[0] if parts else "any"
                required = "required" in parts
                default = ""
                if "=" in line:
                    default = line.split("=", 1)[1].strip()
                model.fields.append(ASTField(field_name, type_name, required, default))
            models.append(model)
        return models
