// Drives the built server over stdio with the Language Server Protocol, as an editor would.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import path from 'node:path';
import { after, before, test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { StreamMessageReader, StreamMessageWriter, createMessageConnection } from 'vscode-jsonrpc/node.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const server = spawn(process.execPath, [path.join(root, 'dist/server.cjs'), '--stdio']);
const connection = createMessageConnection(new StreamMessageReader(server.stdout), new StreamMessageWriter(server.stdin));
const diagnostics = new Map<string, (value: any[]) => void>();
connection.onNotification('textDocument/publishDiagnostics', (params: { uri: string; diagnostics: any[] }) => {
  diagnostics.get(params.uri)?.(params.diagnostics);
});
connection.listen();

const uri = 'file:///tmp/swiftcn-test/PlayerView.swift';
const text = 'Text("Golden Hour").tw("text-2xl font-bld bg-")\n';

before(async () => {
  const result: any = await connection.sendRequest('initialize', {
    processId: process.pid, rootUri: null, capabilities: {}, workspaceFolders: null,
  });
  assert.equal(result.serverInfo.name, 'swiftcn-language-server');
  assert.ok(result.capabilities.completionProvider.triggerCharacters.includes('-'));
  connection.sendNotification('initialized', {});
});

after(() => {
  connection.dispose();
  server.kill();
});

test('publishes a diagnostic with a quick fix for a misspelled class', async () => {
  const published = new Promise<any[]>((resolve) => diagnostics.set(uri, resolve));
  connection.sendNotification('textDocument/didOpen', { textDocument: { uri, languageId: 'swift', version: 1, text } });
  const [diagnostic, ...rest] = await published;
  assert.equal(diagnostic.message, "Unknown swiftcn class 'font-bld'. Did you mean 'font-bold'?");
  assert.deepEqual(diagnostic.range.start, { line: 0, character: text.indexOf('font-bld') });
  assert.equal(rest.length, 1); // The unfinished bg- is reported too.

  const actions: any[] = await connection.sendRequest('textDocument/codeAction', {
    textDocument: { uri }, range: diagnostic.range, context: { diagnostics: [diagnostic] },
  });
  assert.equal(actions[0].title, "Replace with 'font-bold'");
  assert.equal(actions[0].edit.changes[uri][0].newText, 'font-bold');
});

test('completes classes inside the string, replacing the partial class', async () => {
  const character = text.indexOf('bg-') + 3;
  const items: any[] = await connection.sendRequest('textDocument/completion', {
    textDocument: { uri }, position: { line: 0, character },
  });
  const surface = items.find((item) => item.label === 'bg-surface');
  assert.ok(surface, 'bg-surface is offered');
  assert.deepEqual(surface.textEdit.range.start, { line: 0, character: text.indexOf('bg-') });
  assert.equal(surface.documentation, 'Background color: theme color surface.');
  assert.ok(items.some((item) => item.label === 'hover:'));
  assert.ok(items.some((item) => item.label === 'w-[…]' && item.textEdit.newText === 'w-[${1:240}]'));

  const outside: any[] = await connection.sendRequest('textDocument/completion', {
    textDocument: { uri }, position: { line: 0, character: 8 },
  });
  assert.deepEqual(outside, [], 'nothing outside class strings');
});

test('describes a class on hover', async () => {
  const hover: any = await connection.sendRequest('textDocument/hover', {
    textDocument: { uri }, position: { line: 0, character: text.indexOf('text-2xl') + 2 },
  });
  assert.match(hover.contents.value, /Font \.title\. Scales with Dynamic Type\./);
});
