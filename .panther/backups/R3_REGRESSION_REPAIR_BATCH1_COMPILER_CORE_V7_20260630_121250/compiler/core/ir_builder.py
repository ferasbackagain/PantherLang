from compiler.core.ir_nodes import IRProgram, IRModel, IRField


class IRBuilder:
    def build_model(self, model):
        fields = [
            IRField(
                name=field.name,
                type_name=field.type_name,
                required=field.required,
                nullable=field.nullable,
                default=field.default,
            )
            for field in model.fields
        ]
        return IRModel(name=model.name, fields=fields)

    def build_program_from_models(self, models, name="PantherProgram"):
        program = IRProgram(name=name)
        for model in models:
            program.models.append(self.build_model(model))
        return program
