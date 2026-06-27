const vscode = require('vscode');
const cp = require('child_process');

let clientProcess = null;

function activate(context) {
  const output = vscode.window.createOutputChannel('PantherLang');
  context.subscriptions.push(output);

  const disposable = vscode.commands.registerCommand('pantherlang.restartLsp', () => {
    if (clientProcess) {
      clientProcess.kill();
      clientProcess = null;
    }
    vscode.window.showInformationMessage('PantherLang LSP restart requested.');
  });
  context.subscriptions.push(disposable);

  output.appendLine('PantherLang IDE extension activated. Configure pantherlang.lsp.path if needed.');
}

function deactivate() {
  if (clientProcess) {
    clientProcess.kill();
    clientProcess = null;
  }
}

module.exports = { activate, deactivate };
