const vscode = require('vscode');
const path = require('path');
const fs = require('fs');

function getWorkspaceRoot() {
  const folders = vscode.workspace.workspaceFolders;
  return folders && folders.length ? folders[0].uri.fsPath : undefined;
}

async function openAgentGuide() {
  const root = getWorkspaceRoot();
  if (!root) {
    vscode.window.showWarningMessage('Open the PantherLang repository or a PantherLang project first.');
    return;
  }

  const candidates = [
    path.join(root, 'docs', 'agent_knowledge', 'PANTHERLANG_AGENT_GUIDE.md'),
    path.join(root, '..', 'docs', 'agent_knowledge', 'PANTHERLANG_AGENT_GUIDE.md')
  ];

  const guide = candidates.find(fs.existsSync);
  if (!guide) {
    vscode.window.showErrorMessage('PantherLang Agent Guide not found.');
    return;
  }

  const doc = await vscode.workspace.openTextDocument(vscode.Uri.file(guide));
  await vscode.window.showTextDocument(doc, { preview: false });
}

module.exports = { openAgentGuide };
