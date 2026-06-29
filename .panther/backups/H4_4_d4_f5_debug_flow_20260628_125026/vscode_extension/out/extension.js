"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;

const vscode = require("vscode");
const path = require("path");

class PantherDebugAdapterDescriptorFactory {
  createDebugAdapterDescriptor(session, executable) {
    const workspaceFolder =
      (vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0].uri.fsPath) ||
      process.cwd();

    const adapterScript = path.join(workspaceFolder, "debug_adapter", "adapter.py");

    return new vscode.DebugAdapterExecutable("python3", [adapterScript], {
      cwd: workspaceFolder
    });
  }
}

class PantherDebugConfigurationProvider {
  resolveDebugConfiguration(folder, config) {
    if (!config.type) config.type = "panther";
    if (!config.request) config.request = "launch";
    if (!config.name) config.name = "Debug PantherLang File";
    if (!config.program) config.program = "${file}";
    if (!config.cwd) config.cwd = "${workspaceFolder}";
    if (config.dryRun === undefined) config.dryRun = true;
    return config;
  }
}

function activate(context) {
  const factory = new PantherDebugAdapterDescriptorFactory();
  const provider = new PantherDebugConfigurationProvider();

  context.subscriptions.push(
    vscode.debug.registerDebugAdapterDescriptorFactory("panther", factory)
  );

  context.subscriptions.push(
    vscode.debug.registerDebugConfigurationProvider("panther", provider)
  );

  context.subscriptions.push(
    vscode.commands.registerCommand("panther.debug.start", async () => {
      const editor = vscode.window.activeTextEditor;
      const program = editor ? editor.document.uri.fsPath : "${file}";

      await vscode.debug.startDebugging(undefined, {
        name: "Debug PantherLang File",
        type: "panther",
        request: "launch",
        program,
        cwd: "${workspaceFolder}",
        stopOnEntry: true,
        dryRun: true
      });
    })
  );
}

function deactivate() {}
