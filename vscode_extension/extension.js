const vscode = require('vscode');

function runPantherCommand(cmd) {
  const terminal = vscode.window.createTerminal('PantherLang');
  terminal.show();
  terminal.sendText(`Panther ${cmd}`);
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('panther.run', () => runPantherCommand('run'))
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('panther.build', () => runPantherCommand('build'))
  );

  context.subscriptions.push(
    vscode.commands.registerCommand('panther.check', () => runPantherCommand('check'))
  );
}

function deactivate() {}

module.exports = {
  activate,
  deactivate
};
