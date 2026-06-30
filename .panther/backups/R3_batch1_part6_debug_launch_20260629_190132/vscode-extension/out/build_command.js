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

async function buildProject() {
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

  const repoRunner = path.join(root, 'tools', 'project_runner', 'panther_build.py');
  const fallbackRunner = path.join(__dirname, '..', '..', 'tools', 'project_runner', 'panther_build.py');
  const runner = fs.existsSync(repoRunner) ? repoRunner : fallbackRunner;

  const terminal = vscode.window.createTerminal('PantherLang Build');
  terminal.show();

  await vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification,
    title: 'Building PantherLang project',
    cancellable: false
  }, async () => {
    if (fs.existsSync(runner)) {
      const output = await execFile('python3', [runner, '--project', root, '--json'], root);
      terminal.sendText(`echo '${output.replace(/'/g, "'\\''")}'`);
      vscode.window.showInformationMessage('PantherLang build completed.');
    } else {
      terminal.sendText('panther build');
      vscode.window.showInformationMessage('PantherLang build command sent to terminal.');
    }
  });
}

module.exports = { buildProject };
