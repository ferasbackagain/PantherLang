const vscode=require("vscode");
const cp=require("child_process");

async function runCurrentFile(){
 const ed=vscode.window.activeTextEditor;
 if(!ed){vscode.window.showWarningMessage("No PantherLang file open.");return;}
 const file=ed.document.fileName;
 const term=vscode.window.createTerminal("PantherLang Run");
 term.show();
 term.sendText(`panther run "${file}"`);
}
module.exports={runCurrentFile};
