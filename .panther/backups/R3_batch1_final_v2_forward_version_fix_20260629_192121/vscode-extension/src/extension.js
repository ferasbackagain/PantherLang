const {openAgentGuide}=require('./agent_command');
const {debugProject}=require('./debug_command');
const {buildProject}=require('./build_command');
const {runCurrentFile}=require('./run_command');
const vscode = require('vscode');
const cp = require('child_process');
const path = require('path');
const fs = require('fs');

const templates = [
  { id: 'console', label: 'Console App', description: 'Minimal PantherLang command-line application' },
  { id: 'web', label: 'Web App', description: 'PantherLang web application starter' },
  { id: 'api', label: 'API App', description: 'PantherLang REST/API service starter' },
  { id: 'ai', label: 'AI App', description: 'PantherLang AI-ready application starter' }
];

function getWorkspaceRoot() {
  const folders = vscode.workspace.workspaceFolders;
  return folders && folders.length ? folders[0].uri.fsPath : undefined;
}

function runCommand(command, args, cwd) {
  return new Promise((resolve, reject) => {
    cp.execFile(command, args, { cwd }, (error, stdout, stderr) => {
      if (error) reject(new Error(stderr || error.message));
      else resolve(stdout || stderr || '');
    });
  });
}

async function selectDestination() {
  const root = getWorkspaceRoot();
  if (root) {
    const choice = await vscode.window.showQuickPick(
      [
        { label: 'Current Workspace', description: root, value: root },
        { label: 'Choose Folder...', description: 'Select another destination', value: '__choose__' }
      ],
      { placeHolder: 'Choose where to create the PantherLang project' }
    );
    if (!choice) return undefined;
    if (choice.value !== '__choose__') return choice.value;
  }

  const selected = await vscode.window.showOpenDialog({
    canSelectFiles: false,
    canSelectFolders: true,
    canSelectMany: false,
    openLabel: 'Select PantherLang Project Destination'
  });
  return selected && selected.length ? selected[0].fsPath : undefined;
}

function validateProjectName(value) {
  if (!value || !value.trim()) return 'Project name is required';
  if (!/^[A-Za-z0-9_-]+$/.test(value.trim())) return 'Use only letters, numbers, dash, and underscore';
  return null;
}

async function createProject(templateId) {
  let template = templateId;
  if (!template) {
    const picked = await vscode.window.showQuickPick(
      templates.map(t => ({ label: t.label, description: t.description, value: t.id })),
      { placeHolder: 'Select PantherLang project template' }
    );
    if (!picked) return;
    template = picked.value;
  }

  const projectName = await vscode.window.showInputBox({
    prompt: 'PantherLang project name',
    value: template === 'console' ? 'hello-panther' : `hello-${template}`,
    validateInput: validateProjectName
  });
  if (!projectName) return;

  const destination = await selectDestination();
  if (!destination) return;

  const workspaceRoot = getWorkspaceRoot() || destination;
  const scriptCandidates = [
    path.join(workspaceRoot, 'tools', 'project_wizard', 'panther_new.py'),
    path.join(destination, 'tools', 'project_wizard', 'panther_new.py')
  ];
  const script = scriptCandidates.find(fs.existsSync);
  if (!script) {
    vscode.window.showErrorMessage('PantherLang project wizard script not found. Open the PantherLang repository workspace first.');
    return;
  }

  await vscode.window.withProgress({
    location: vscode.ProgressLocation.Notification,
    title: `Creating PantherLang ${template} project`,
    cancellable: false
  }, async () => {
    const output = await runCommand('python3', [script, projectName, '--template', template, '--destination', destination, '--json'], workspaceRoot);
    const data = JSON.parse(output);
    const createdPath = data.destination;
    const open = await vscode.window.showInformationMessage(
      `Created PantherLang ${template} project: ${projectName}`,
      'Open Project',
      'Show Files'
    );
    if (open === 'Open Project') {
      await vscode.commands.executeCommand('vscode.openFolder', vscode.Uri.file(createdPath), { forceNewWindow: false });
    } else if (open === 'Show Files') {
      await vscode.commands.executeCommand('revealFileInOS', vscode.Uri.file(createdPath));
    }
  });
}

async function doctor() {
  const root = getWorkspaceRoot() || process.cwd();
  const terminal = vscode.window.createTerminal('PantherLang Doctor');
  terminal.show();
  terminal.sendText(`cd "${root}" && python3 - <<'PY'\nfrom panther_core.version import get_release_info\nprint(get_release_info())\nPY`);
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
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newProject', () => createProject(undefined)));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newConsoleProject', () => createProject('console')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newWebProject', () => createProject('web')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newApiProject', () => createProject('api')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.newAiProject', () => createProject('ai')));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.doctor', doctor));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.runFile', runFile));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.buildProject', buildProject));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.debugProject', debugProject));
  context.subscriptions.push(vscode.commands.registerCommand('pantherlang.openAgentGuide', openAgentGuide));
}

function deactivate() {}

module.exports = { activate, deactivate };
