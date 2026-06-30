def semantic_to_ir(semantic):
    return {
        "kind": "PantherIR",
        "version": "0.5",
        "app": {
            "name": semantic.app_name,
            "version": semantic.version,
            "targets": semantic.targets,
            "description": semantic.description,
        },
        "data": [{"name": m.name, "fields": [f.__dict__ for f in m.fields]} for m in semantic.data_models],
        "apis": [a.__dict__ for a in semantic.apis],
        "ui": [p.__dict__ for p in semantic.pages],
        "workflows": semantic.workflows,
        "agents": semantic.agents,
        "devices": semantic.devices,
        "tasks": semantic.tasks,
        "security": semantic.security,
        "deploy": semantic.deploy,
    }
