"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createPantherF5DebugConfiguration = createPantherF5DebugConfiguration;
exports.startPantherF5Debug = startPantherF5Debug;

const vscode = require("vscode");

function createPantherF5DebugConfiguration(program) {
  return {
    name: "PantherLang: F5 Debug Current File",
    type: "panther",
    request: "launch",
    program,
    cwd: "${workspaceFolder}",
    stopOnEntry: true,
    dryRun: true,
    preLaunchTask: "PantherLang: Check"
  };
}

async function startPantherF5Debug(program) {
  const config = createPantherF5DebugConfiguration(program);
  return vscode.debug.startDebugging(undefined, config);
}
