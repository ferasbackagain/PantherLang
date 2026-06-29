"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;

const vscode = require("vscode");
const path = require("path");
const debugFlow = require("./debugFlow");

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
  provideDebugConfigurations(folder) {
    return [
      {
        name: "PantherLang: F5 Debug Current File",
        type: "panther",
        request: "launch",
        program: "${file}",
        cwd: "${workspaceFolder}",
        stopOnEntry: true,
        dryRun: true,
        preLaunchTask: "PantherLang: Check"
      },
      {
        name: "PantherLang: Debug Example hello.pan",
        type: "panther",
        request: "launch",
        program: "${workspaceFolder}/examples/hello.pan",
        cwd: "${workspaceFolder}",
        stopOnEntry: true,
        dryRun: true,
        preLaunchTask: "PantherLang: Check Example"
      }
    ];
  }

  resolveDebugConfiguration(folder, config) {
    if (!config.type) config.type = "panther";
    if (!config.request) config.request = "launch";
    if (!config.name) config.name = "PantherLang: F5 Debug Current File";
    if (!config.program) config.program = "${file}";
    if (!config.cwd) config.cwd = "${workspaceFolder}";
    if (config.stopOnEntry === undefined) config.stopOnEntry = true;
    if (config.dryRun === undefined) config.dryRun = true;
    if (!config.preLaunchTask) config.preLaunchTask = "PantherLang: Check";
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
      // compatibility marker for D2 regression: vscode.debug.startDebugging
      return debugFlow.startPantherF5Debug(program);
    })
  );
}

function deactivate() {}
