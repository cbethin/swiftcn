// Runs suite.cjs inside a real editor with the extension loaded, in a throwaway profile:
//   node test/editor/run.mjs                       downloads and uses the latest VS Code
//   node test/editor/run.mjs "/Applications/Cursor.app/Contents/MacOS/Cursor"
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { runTests } from '@vscode/test-electron';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const profile = mkdtempSync(path.join(tmpdir(), 'swiftcn-editor-test-'));
const workspace = path.join(profile, 'workspace');
mkdirSync(workspace);
writeFileSync(path.join(workspace, 'PlayerView.swift'), 'Text("Golden Hour").tw("text-2xl font-bld bg-")\n');
try {
  await runTests({
    vscodeExecutablePath: process.argv[2],
    extensionDevelopmentPath: root,
    extensionTestsPath: path.join(root, 'test/editor/suite.cjs'),
    launchArgs: [workspace, '--disable-extensions', '--user-data-dir', path.join(profile, 'user'),
                 '--extensions-dir', path.join(profile, 'extensions'), '--skip-welcome', '--disable-workspace-trust'],
  });
} finally {
  rmSync(profile, { recursive: true, force: true });
}
