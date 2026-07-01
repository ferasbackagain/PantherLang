import * as vscode from "vscode";
import * as path from "path";

export function resolvePantherDebugAdapterPath(context: vscode.ExtensionContext): string {
    return path.join(context.extensionPath, "..", "debug_adapter", "adapter.py");
}

export function createPantherF5DebugConfiguration(): vscode.DebugConfiguration {
    return {
        type: "panther",
        request: "launch",
        name: "PantherLang: Debug Current File",
        program: "${file}",
        dryRun: true
    };
}

export function startPantherF5Debug(): Thenable<boolean> {
    const folder = vscode.workspace.workspaceFolders ? vscode.workspace.workspaceFolders[0] : undefined;
    return vscode.debug.startDebugging(folder, createPantherF5DebugConfiguration());
}

export function startPantherDebugging(): Thenable<boolean> {
    return startPantherF5Debug();
}

export function registerPantherDebug(context: vscode.ExtensionContext): void {
    const provider: vscode.DebugConfigurationProvider = {
        provideDebugConfigurations() {
            return [createPantherF5DebugConfiguration()];
        },
        resolveDebugConfiguration(_folder, config) {
            return config && Object.keys(config).length ? config : createPantherF5DebugConfiguration();
        }
    };

    context.subscriptions.push(
        vscode.debug.registerDebugConfigurationProvider("panther", provider),
        vscode.debug.registerDebugAdapterDescriptorFactory("panther", {
            createDebugAdapterDescriptor() {
                return new vscode.DebugAdapterExecutable("python3", [resolvePantherDebugAdapterPath(context)]);
            }
        }),
        vscode.commands.registerCommand("panther.debug.start", startPantherF5Debug)
    );
}
