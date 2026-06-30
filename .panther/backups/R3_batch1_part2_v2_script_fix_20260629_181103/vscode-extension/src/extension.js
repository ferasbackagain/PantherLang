const vscode = require('vscode');
const cp = require('child_process');
const path = require('path');

function runCommand(command, args, cwd) {
  return new Promise((resolve, reject) => {
    cp.execFile(command, args, { cwd }, (error, stdout, stderr) => {
      if (error) reject(new Error(stderr || error.message));
      else resolve(stdout || stderr || '');
    });
  });
}

async function createProject(template) {
  const name = await vscode.window.showInputBox({
    prompt: `New PantherLang ${template} project name`,
    value: template === 'console' ? 'hello-panther' : `hello-${template}`
  });
  if (!name) return;

  const folders = vscode.workspace.workspaceFolders;
  const destination = folders && folders.length ? folders[0].uri.fsPath : process.cwd();
  const root = folders && folders.length ? folders[0].uri.fsPath : destination;
  const script = path.join(root, 'tools', 'project_wizard', 'panther_new.py');

  try {
    await runCommand('python3', [script, name, '--template', template, '--destination', destination, '--json'], root);
    vscode.window.showInformationMessage(`PantherLang project created: ${name}`);
    await vscode.commands.executeCommand('vscode.openFolder', vscode.Uri.file(path.join(destination, name)), { forceNewWindow: false });
  } catch (err) {
    vscode.window.showErrorMessage(`PantherLang project creation failed: ${err.message}`);
  }
}

async function doctor() {
  vscode.window.showInformationMessage('PantherLang v1.0.1 Developer Experience: extension active.');
}

async function runFile() {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    vscode.window.showWarningMessage('No active PantherLang file.');
    return;
  }
  const terminal = vscode.window.createTerminal('PantherLang');
  terminal.show();
  terminal.sendText(`echo "PantherLang run placeholder: ${editor.document.fileName}"`);
}

function activate(context) {
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newProject', () => createProject('console')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newConsoleProject', () => createProject('console')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newWebProject', () => createProject('web')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newApiProject', () => createProject('api')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newAiProject', () => createProject('ai')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.doctor', doctor));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.runFile', runFile));
}

function deactivate() {}

module.exports = { activate, deactivate };
