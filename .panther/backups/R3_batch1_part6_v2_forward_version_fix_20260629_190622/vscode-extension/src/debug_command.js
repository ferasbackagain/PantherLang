const vscode = require('vscode');
const cp = require('child_process');
const path = require('path');
const fs = require('fs');

function getWorkspaceRoot() {
  const folders = vscode.workspace.workspaceFolders;
  return folders && folders.length ? folders[0].uri.fsPath : undefined;
}

function execFile(command, args, cwd) {
  return new Promise((resolve, reject) => {
    cp.execFile(command, args, { cwd }, (error, stdout, stderr) => {
      if (error) reject(new Error(stderr || error.message));
      else resolve(stdout || stderr || '');
    });
  });
}

async function debugProject() {
  const root = getWorkspaceRoot();
  if (!root) {
    vscode.window.showWarningMessage('Open a PantherLang project folder first.');
    return;
  }

  const manifest = path.join(root, 'panther.toml');
  if (!fs.existsSync(manifest)) {
    vscode.window.showErrorMessage('panther.toml not found. Open a PantherLang project root.');
    return;
  }

  const program = path.join(root, 'src', 'main.panther');
  const repoHelper = path.join(root, 'tools', 'project_runner', 'panther_debug.py');
  const fallbackHelper = path.join(__dirname, '..', '..', 'tools', 'project_runner', 'panther_debug.py');
  const helper = fs.existsSync(repoHelper) ? repoHelper : fallbackHelper;

  if (fs.existsSync(helper)) {
    await execFile('python3', [helper, '--project', root, '--program', program, '--json'], root);
  }

  const config = {
    type: 'pantherlang',
    request: 'launch',
    name: 'Debug PantherLang Program',
    program: program,
    dryRun: true
  };

  const started = await vscode.debug.startDebugging(vscode.workspace.workspaceFolders[0], config);
  if (started) {
    vscode.window.showInformationMessage('PantherLang debug session started.');
  } else {
    vscode.window.showWarningMessage('PantherLang debug session did not start.');
  }
}

module.exports = { debugProject };
