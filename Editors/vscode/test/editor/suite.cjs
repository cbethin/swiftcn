// Runs inside the editor's extension host: opens a Swift document and asks the editor, not the
// server, for completions, diagnostics, and hover, so the whole extension path is exercised.
const assert = require('node:assert/strict');
const vscode = require('vscode');

const text = 'Text("Golden Hour").tw("text-2xl font-bld bg-")\n';

async function eventually(read, check, label) {
  for (let attempt = 0; attempt < 100; attempt++) {
    const value = await read();
    if (check(value)) return value;
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
  throw new Error(`Timed out waiting for ${label}`);
}

exports.run = async function run() {
  // The workspace folder holds PlayerView.swift with this text. Opening the document is enough for
  // the language client to sync it; showing an editor is not needed.
  const [file] = await vscode.workspace.findFiles('PlayerView.swift');
  const document = await vscode.workspace.openTextDocument(file);
  assert.equal(document.getText(), text);

  const diagnostics = await eventually(
    () => vscode.languages.getDiagnostics(document.uri),
    (list) => list.some((item) => item.source === 'swiftcn'),
    'swiftcn diagnostics');
  const typo = diagnostics.find((item) => item.message.includes('font-bld'));
  assert.equal(typo.message, "Unknown swiftcn class 'font-bld'. Did you mean 'font-bold'?");
  assert.equal(typo.severity, vscode.DiagnosticSeverity.Warning);

  const actions = await vscode.commands.executeCommand('vscode.executeCodeActionProvider', document.uri, typo.range);
  assert.ok(actions.some((action) => action.title === "Replace with 'font-bold'"), 'quick fix offered');

  const position = new vscode.Position(0, text.indexOf('bg-') + 3);
  const completions = await vscode.commands.executeCommand('vscode.executeCompletionItemProvider', document.uri, position);
  const labels = completions.items.map((item) => (typeof item.label === 'string' ? item.label : item.label.label));
  assert.ok(labels.includes('bg-surface'), 'bg-surface completion');
  assert.ok(labels.includes('hover:'), 'variant completion');

  const hovers = await vscode.commands.executeCommand('vscode.executeHoverProvider', document.uri,
    new vscode.Position(0, text.indexOf('text-2xl') + 2));
  const hoverText = hovers.flatMap((hover) => hover.contents).map((content) => content.value ?? content).join('\n');
  assert.match(hoverText, /Font \.title\. Scales with Dynamic Type\./);

  console.log(`swiftcn editor test passed in ${vscode.env.appName} ${vscode.version}`);
};
