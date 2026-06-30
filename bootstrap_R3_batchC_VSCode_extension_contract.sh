#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
BATCH="R3_batchC_vscode_extension_contract"
TS="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$ROOT/.panther/backups/${BATCH}_${TS}"
REPORT_DIR="$ROOT/.panther/reports/${BATCH}_${TS}"
mkdir -p "$BACKUP_DIR" "$REPORT_DIR"

if [ ! -d "$ROOT/vscode-extension" ]; then
  echo "ERROR: vscode-extension directory not found. Run this from PantherLang project root." >&2
  exit 1
fi

cp -a "$ROOT/vscode-extension" "$BACKUP_DIR/vscode-extension"
[ -f "$ROOT/.vscode/launch.json" ] && mkdir -p "$BACKUP_DIR/.vscode" && cp "$ROOT/.vscode/launch.json" "$BACKUP_DIR/.vscode/launch.json" || true
[ -f "$ROOT/.vscode/tasks.json" ] && mkdir -p "$BACKUP_DIR/.vscode" && cp "$ROOT/.vscode/tasks.json" "$BACKUP_DIR/.vscode/tasks.json" || true

python3 - <<'PY'
import json
from pathlib import Path
root = Path.cwd()
ext_dir = root / "vscode-extension"
pkg = ext_dir / "package.json"
data = json.loads(pkg.read_text(encoding="utf-8"))

data["displayName"] = "PantherLang"
# keep current version if present, but ensure valid
if not data.get("version"):
    data["version"] = "1.1.3"

activation = list(dict.fromkeys(data.get("activationEvents", [])))
for ev in ["onDebug", "onCommand:panther.debug.start", "onLanguage:panther"]:
    if ev not in activation:
        activation.append(ev)
data["activationEvents"] = activation

contrib = data.setdefault("contributes", {})
commands = contrib.setdefault("commands", [])
if not any(c.get("command") == "panther.debug.start" for c in commands):
    commands.append({"command": "panther.debug.start", "title": "Panther: Start Debugging"})

langs = contrib.setdefault("languages", [])
if not any(l.get("id") == "panther" for l in langs):
    langs.append({"id": "panther", "aliases": ["PantherLang", "panther"], "extensions": [".pan", ".panther"]})
else:
    for l in langs:
        if l.get("id") == "panther":
            exts = list(dict.fromkeys(l.get("extensions", []) + [".pan", ".panther"]))
            l["extensions"] = exts
            l.setdefault("aliases", ["PantherLang", "panther"])

debuggers = contrib.setdefault("debuggers", [])
if not any(d.get("type") == "panther" for d in debuggers):
    debuggers.append({
        "type": "panther",
        "label": "PantherLang Debug",
        "program": "./out/extension.js",
        "runtime": "node",
        "configurationAttributes": {
            "launch": {
                "required": ["program"],
                "properties": {
                    "program": {"type": "string", "description": "PantherLang program to debug"},
                    "dryRun": {"type": "boolean", "default": True}
                }
            }
        },
        "initialConfigurations": [{
            "type": "panther",
            "request": "launch",
            "name": "Debug Panther Program",
            "program": "${workspaceFolder}/examples/hello.pan",
            "dryRun": True
        }]
    })
else:
    for d in debuggers:
        if d.get("type") == "panther":
            d["label"] = "PantherLang Debug"
            d["program"] = "./out/extension.js"
            d["runtime"] = "node"

pkg.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")

# Ensure workspace debug files
vscode = root / ".vscode"
vscode.mkdir(exist_ok=True)
launch = vscode / "launch.json"
launch_data = {"version":"0.2.0", "configurations":[{"type":"panther","request":"launch","name":"Debug Panther Program","program":"${workspaceFolder}/examples/hello.pan","dryRun": True}]}
if launch.exists():
    try:
        old = json.loads(launch.read_text(encoding="utf-8"))
        configs = old.setdefault("configurations", [])
        if not any(c.get("type") == "panther" for c in configs):
            configs.append(launch_data["configurations"][0])
        launch_data = old
    except Exception:
        pass
launch.write_text(json.dumps(launch_data, indent=2) + "\n", encoding="utf-8")

tasks = vscode / "tasks.json"
task_data = {"version":"2.0.0", "tasks":[{"label":"Panther: Run Current File","type":"shell","command":"./panther run ${file}","problemMatcher":[]}]}
if tasks.exists():
    try:
        old = json.loads(tasks.read_text(encoding="utf-8"))
        arr = old.setdefault("tasks", [])
        if not any(t.get("label") == "Panther: Run Current File" for t in arr):
            arr.append(task_data["tasks"][0])
        task_data = old
    except Exception:
        pass
tasks.write_text(json.dumps(task_data, indent=2) + "\n", encoding="utf-8")
PY

# Provide/refresh debug flow JS and source registration in both TS and JS output.
mkdir -p vscode-extension/src vscode-extension/out
cat > vscode-extension/src/debugFlow.ts <<'EOF2'
import * as vscode from 'vscode';
import * as path from 'path';

export function resolvePantherDebugAdapterPath(context: vscode.ExtensionContext): string {
  return path.join(context.extensionPath, '..', 'debug_adapter', 'adapter.py');
}

export async function startPantherDebugging(): Promise<void> {
  const editor = vscode.window.activeTextEditor;
  const program = editor?.document?.fileName || '${workspaceFolder}/examples/hello.pan';
  await vscode.debug.startDebugging(undefined, {
    type: 'panther',
    request: 'launch',
    name: 'Debug Panther Program',
    program,
    dryRun: true,
  });
}

export function registerPantherDebug(context: vscode.ExtensionContext): void {
  const factory: vscode.DebugAdapterDescriptorFactory = {
    createDebugAdapterDescriptor: () => {
      const adapter = resolvePantherDebugAdapterPath(context);
      return new vscode.DebugAdapterExecutable('python3', [adapter]);
    },
  };
  context.subscriptions.push(vscode.debug.registerDebugAdapterDescriptorFactory('panther', factory));
  context.subscriptions.push(vscode.debug.registerDebugConfigurationProvider('panther', {
    resolveDebugConfiguration(_folder, config) {
      config.type = config.type || 'panther';
      config.name = config.name || 'Debug Panther Program';
      config.request = config.request || 'launch';
      config.program = config.program || '${workspaceFolder}/examples/hello.pan';
      return config;
    },
  }));
  context.subscriptions.push(vscode.commands.registerCommand('panther.debug.start', startPantherDebugging));
}
EOF2
cat > vscode-extension/out/debugFlow.js <<'EOF2'
const vscode = require('vscode');
const path = require('path');
function resolvePantherDebugAdapterPath(context) {
  return path.join(context.extensionPath, '..', 'debug_adapter', 'adapter.py');
}
async function startPantherDebugging() {
  const editor = vscode.window.activeTextEditor;
  const program = (editor && editor.document && editor.document.fileName) || '${workspaceFolder}/examples/hello.pan';
  await vscode.debug.startDebugging(undefined, {
    type: 'panther',
    request: 'launch',
    name: 'Debug Panther Program',
    program,
    dryRun: true,
  });
}
function registerPantherDebug(context) {
  const factory = {
    createDebugAdapterDescriptor: () => {
      const adapter = resolvePantherDebugAdapterPath(context);
      return new vscode.DebugAdapterExecutable('python3', [adapter]);
    },
  };
  context.subscriptions.push(vscode.debug.registerDebugAdapterDescriptorFactory('panther', factory));
  context.subscriptions.push(vscode.debug.registerDebugConfigurationProvider('panther', {
    resolveDebugConfiguration(_folder, config) {
      config.type = config.type || 'panther';
      config.name = config.name || 'Debug Panther Program';
      config.request = config.request || 'launch';
      config.program = config.program || '${workspaceFolder}/examples/hello.pan';
      return config;
    },
  }));
  context.subscriptions.push(vscode.commands.registerCommand('panther.debug.start', startPantherDebugging));
}
module.exports = { resolvePantherDebugAdapterPath, startPantherDebugging, registerPantherDebug };
EOF2

python3 - <<'PY'
from pathlib import Path
root = Path.cwd()
for rel in ["vscode-extension/src/extension.ts", "vscode-extension/out/extension.js"]:
    p = root / rel
    if not p.exists():
        continue
    s = p.read_text(encoding="utf-8")
    if rel.endswith("extension.ts"):
        if "./debugFlow" not in s:
            s = "import { registerPantherDebug } from './debugFlow';\n" + s
        if "registerPantherDebug(context)" not in s:
            # insert inside activate if possible, else append
            marker = "function activate(context"
            if marker in s:
                idx = s.find("{", s.find(marker))
                s = s[:idx+1] + "\n    registerPantherDebug(context);\n" + s[idx+1:]
            else:
                s += "\nexport function activate(context: any) { registerPantherDebug(context); }\n"
    else:
        if 'require("./debugFlow")' not in s and "require('./debugFlow')" not in s:
            s = "const { registerPantherDebug } = require(\"./debugFlow\");\n" + s
        if "registerPantherDebug(context)" not in s:
            marker = "function activate(context)"
            if marker in s:
                idx = s.find("{", s.find(marker))
                s = s[:idx+1] + "\n    registerPantherDebug(context);\n" + s[idx+1:]
            else:
                s += "\nfunction activate(context) { registerPantherDebug(context); }\n"
    p.write_text(s, encoding="utf-8")
PY

cat > "$REPORT_DIR/REPORT.md" <<EOF2
# R3 Batch C — VS Code Extension Contract

Applied at: $TS

Scope:
- package.json debug activation contract
- panther.debug.start command contribution
- debug adapter descriptor registration in src/out
- debugFlow source/output presence
- package displayName normalization
- workspace launch/tasks debug scaffolding

Backup:
$BACKUP_DIR
EOF2

cat > "$ROOT/BATCH_C_MANIFEST.json" <<EOF2
{"batch":"R3 Batch C","scope":"VS Code Extension Contract","timestamp":"$TS","backup":"$BACKUP_DIR","report":"$REPORT_DIR"}
EOF2

echo "R3 Batch C VS Code Extension Contract applied."
echo "Backup: $BACKUP_DIR"
echo "Report: $REPORT_DIR"
echo "Now run Batch C targeted regression from README_RUN_ORDER.md"
