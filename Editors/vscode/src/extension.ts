// Starts the swiftcn language server for Swift files in VS Code, Cursor, Windsurf, and VSCodium.
import * as path from 'node:path';
import { workspace, type ExtensionContext } from 'vscode';
import { LanguageClient, TransportKind, type LanguageClientOptions, type ServerOptions } from 'vscode-languageclient/node.js';

let client: LanguageClient | undefined;

export async function activate(context: ExtensionContext): Promise<void> {
  const module = context.asAbsolutePath(path.join('dist', 'server.cjs'));
  const serverOptions: ServerOptions = {
    run: { module, transport: TransportKind.ipc },
    debug: { module, transport: TransportKind.ipc, options: { execArgv: ['--nolazy', '--inspect=6009'] } },
  };
  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'swift' }, { scheme: 'untitled', language: 'swift' }],
    synchronize: { configurationSection: 'swiftcn', fileEvents: workspace.createFileSystemWatcher('**/*.swift') },
    initializationOptions: {
      retriggerAfterVariant: true,
      diagnostics: { severity: workspace.getConfiguration('swiftcn').get('diagnostics.severity', 'warning') },
    },
  };
  client = new LanguageClient('swiftcn', 'swiftcn', serverOptions, clientOptions);
  await client.start();
}

export function deactivate(): Promise<void> | undefined {
  return client?.stop();
}
