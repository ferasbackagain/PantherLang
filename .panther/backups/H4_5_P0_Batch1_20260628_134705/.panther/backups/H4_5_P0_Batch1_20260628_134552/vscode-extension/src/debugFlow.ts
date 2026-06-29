import * as vscode from 'vscode';

export interface PantherDebugFlowConfig {
  name: string;
  type: string;
  request: string;
  program: string;
  cwd: string;
  stopOnEntry: boolean;
  dryRun: boolean;
  preLaunchTask?: string;
}

export function createPantherF5DebugConfiguration(program: string): PantherDebugFlowConfig {
  return {
    name: 'PantherLang: F5 Debug Current File',
    type: 'panther',
    request: 'launch',
    program,
    cwd: '${workspaceFolder}',
    stopOnEntry: true,
    dryRun: true,
    preLaunchTask: 'PantherLang: Check'
  };
}

export async function startPantherF5Debug(program: string): Promise<boolean> {
  const config = createPantherF5DebugConfiguration(program);
  return vscode.debug.startDebugging(undefined, config);
}
