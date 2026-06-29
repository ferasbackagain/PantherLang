const vscode = require('vscode');
const cp = require('child_process');

function runCommand(command, document) {
  if (!document || document.languageId !== 'panther') {
    vscode.window.showWarningMessage('Open a .panther file first.');
    return;
  }

  const file = document.fileName;
  const terminal = vscode.window.createTerminal('PantherLang');
  terminal.show();
  terminal.sendText(`${command} "${file}"`);
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('panther.runFile', () => {
      runCommand('Panther run', vscode.window.activeTextEditor?.document);
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('panther.checkFile', () => {
      runCommand('Panther check', vscode.window.activeTextEditor?.document);
    })
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('panther.formatFile', () => {
      runCommand('Panther fmt --write', vscode.window.activeTextEditor?.document);
    })
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
