// The swiftcn language server: completions, hover docs, and fixes for classes inside Swift strings.
// The VS Code extension runs it over IPC; other editors run `swiftcn-language-server --stdio`.
import {
  CodeActionKind,
  CompletionItemKind,
  DiagnosticSeverity,
  InsertTextFormat,
  MarkupKind,
  ProposedFeatures,
  TextDocumentSyncKind,
  TextDocuments,
  createConnection,
  type CompletionItem,
  type Diagnostic,
} from 'vscode-languageserver/node.js';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { check, classes, describe, patterns, splitVariants, variants } from './catalog.ts';
import { classLiterals, classTokens, emptyLearned, learn, literalAt, scan, type Learned } from './scanner.ts';

type Severity = 'warning' | 'error' | 'off';

const connection = createConnection(ProposedFeatures.all);
const documents = new TextDocuments(TextDocument);
const learnedByFile = new Map<string, Learned>();
let severity: Severity = 'warning';
let retriggerAfterVariant = false;
let roots: string[] = [];

function allLearned(): Learned {
  const merged = emptyLearned();
  for (const learned of learnedByFile.values()) {
    for (const key of ['named', 'prefixes', 'animations', 'colors'] as const) {
      for (const name of learned[key]) merged[key].add(name);
    }
  }
  return merged;
}

connection.onInitialize((params) => {
  const options = params.initializationOptions ?? {};
  severity = options.diagnostics?.severity ?? severity;
  retriggerAfterVariant = options.retriggerAfterVariant === true;
  roots = (params.workspaceFolders ?? []).map((folder) => fileURLToPath(folder.uri));
  if (!roots.length && params.rootUri) roots = [fileURLToPath(params.rootUri)];
  return {
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Incremental,
      completionProvider: { triggerCharacters: ['"', ' ', '-', ':'] },
      hoverProvider: true,
      codeActionProvider: { codeActionKinds: [CodeActionKind.QuickFix] },
    },
    serverInfo: { name: 'swiftcn-language-server', version: '0.1.0' },
  };
});

connection.onInitialized(async () => {
  for (const root of roots) await learnDirectory(root, 0);
  documents.all().forEach(validate);
});

const skipped = new Set(['.build', 'DerivedData', 'node_modules', 'Pods', 'Carthage', '.swiftpm']);

/** Learns the names that the workspace registers, so classes that use them are not reported. */
async function learnDirectory(directory: string, depth: number): Promise<void> {
  if (depth > 12 || learnedByFile.size > 5000) return;
  let entries;
  try { entries = await readdir(directory, { withFileTypes: true }); } catch { return; }
  for (const entry of entries) {
    if (entry.name.startsWith('.') || skipped.has(entry.name)) continue;
    const full = path.join(directory, entry.name);
    if (entry.isDirectory()) await learnDirectory(full, depth + 1);
    else if (entry.name.endsWith('.swift')) await learnFile(full);
  }
}

async function learnFile(file: string): Promise<void> {
  const uri = pathToFileURL(file).href;
  if (documents.get(uri)) return;
  try { learnedByFile.set(uri, learn(scan(await readFile(file, 'utf8')).tokens)); } catch { learnedByFile.delete(uri); }
}

connection.onDidChangeWatchedFiles(async ({ changes }) => {
  for (const change of changes) {
    if (!change.uri.endsWith('.swift')) continue;
    if (change.type === 3) learnedByFile.delete(change.uri);
    else await learnFile(fileURLToPath(change.uri));
  }
  documents.all().forEach(validate);
});

connection.onDidChangeConfiguration((change) => {
  severity = change.settings?.swiftcn?.diagnostics?.severity ?? severity;
  documents.all().forEach(validate);
});

documents.onDidChangeContent(({ document }) => {
  learnedByFile.set(document.uri, learn(scan(document.getText()).tokens));
  validate(document);
});

documents.onDidClose(({ document }) => connection.sendDiagnostics({ uri: document.uri, diagnostics: [] }));

function readable(text: string): string {
  return text.replaceAll('￼', '\\(…)');
}

function validate(document: TextDocument): void {
  if (severity === 'off') {
    connection.sendDiagnostics({ uri: document.uri, diagnostics: [] });
    return;
  }
  const { tokens, ignoredLines } = scan(document.getText());
  const learned = allLearned();
  const diagnostics: Diagnostic[] = [];
  for (const literal of classLiterals(tokens)) {
    for (const token of classTokens(literal)) {
      if (token.interpolatedOutsideBrackets) continue;
      const problem = check(token.text, learned);
      if (!problem) continue;
      const range = { start: document.positionAt(token.start), end: document.positionAt(token.end) };
      if (ignoredLines.has(range.start.line)) continue;
      diagnostics.push({
        range,
        severity: severity === 'error' ? DiagnosticSeverity.Error : DiagnosticSeverity.Warning,
        source: 'swiftcn',
        code: 'unknown-class',
        message: readable(problem.message),
        data: problem.suggestion ? { suggestion: problem.suggestion } : undefined,
      });
    }
  }
  connection.sendDiagnostics({ uri: document.uri, diagnostics });
}

connection.onCompletion(({ textDocument, position }) => {
  const document = documents.get(textDocument.uri);
  if (!document) return [];
  const text = document.getText();
  const offset = document.offsetAt(position);
  const literal = literalAt(classLiterals(scan(text).tokens), offset);
  if (!literal) return [];

  // The class being typed runs back to whitespace or the start of the literal.
  let start = offset;
  while (start > literal.contentStart && !/\s/.test(text[start - 1])) start--;
  const typed = text.slice(start, offset);
  if (typed.includes('\\(')) return [];
  const parts = splitVariants(typed);
  const segment = parts[parts.length - 1];
  if (/\[[^\]]*$/.test(segment)) return []; // Inside a bracket value.
  const range = { start: document.positionAt(offset - segment.length), end: position };
  const learned = allLearned();

  const items: CompletionItem[] = [];
  for (const entry of classes) {
    if (entry.kind === 'internal') continue;
    items.push({
      label: entry.name,
      kind: entry.kind === 'color' ? CompletionItemKind.EnumMember : CompletionItemKind.Value,
      detail: entry.category,
      documentation: entry.description,
      textEdit: { range, newText: entry.name },
      sortText: `1${entry.name}`,
    });
  }
  for (const name of learned.named) {
    if (classes.some((entry) => entry.name === name)) continue;
    items.push({
      label: name, kind: CompletionItemKind.Variable, detail: 'Registered in your project',
      textEdit: { range, newText: name }, sortText: `0${name}`,
    });
  }
  for (const name of learned.animations) {
    items.push({ label: `animate-${name}`, kind: CompletionItemKind.Variable, detail: 'Animation registered in your project',
      textEdit: { range, newText: `animate-${name}` }, sortText: `0animate-${name}` });
  }
  for (const color of learned.colors) {
    for (const prefix of ['text-', 'bg-', 'border-', 'tint-']) {
      items.push({ label: prefix + color, kind: CompletionItemKind.EnumMember, detail: 'Color registered in your project',
        textEdit: { range, newText: prefix + color }, sortText: `0${prefix}${color}` });
    }
  }
  for (const pattern of patterns) {
    if (!pattern.snippet) continue;
    items.push({
      label: pattern.label,
      kind: CompletionItemKind.Snippet,
      detail: 'swiftcn pattern',
      documentation: pattern.description,
      insertTextFormat: InsertTextFormat.Snippet,
      filterText: pattern.snippet.replace(/\$\{\d+:([^}]*)\}/g, '$1'),
      textEdit: { range, newText: pattern.snippet },
      sortText: `2${pattern.label}`,
    });
  }
  for (const variant of variants) {
    items.push({
      label: `${variant.name}:`,
      kind: CompletionItemKind.Keyword,
      detail: 'Variant',
      documentation: variant.description,
      textEdit: { range, newText: `${variant.name}:` },
      sortText: `3${variant.name}`,
      command: retriggerAfterVariant ? { title: 'Suggest classes', command: 'editor.action.triggerSuggest' } : undefined,
    });
  }
  return items;
});

connection.onHover(({ textDocument, position }) => {
  const document = documents.get(textDocument.uri);
  if (!document) return null;
  const offset = document.offsetAt(position);
  const literal = literalAt(classLiterals(scan(document.getText()).tokens), offset);
  if (!literal) return null;
  const token = classTokens(literal).find((candidate) => offset >= candidate.start && offset <= candidate.end);
  if (!token) return null;
  const learned = allLearned();
  const parts = splitVariants(token.text);
  const name = parts[parts.length - 1];
  const lines = [`**\`${readable(token.text)}\`**`];
  const description = describe(name, learned);
  if (description) {
    lines.push(description.description, `_${description.category}_`);
  } else if (token.text.includes('￼')) {
    lines.push('Argument with an interpolated Swift value.');
  } else {
    lines.push(check(token.text, learned)?.message ?? 'Not a swiftcn class.');
  }
  for (const variant of parts.slice(0, -1)) {
    const entry = variants.find((candidate) => candidate.name === variant.split('/')[0]);
    if (entry) lines.push(`\`${variant}:\` ${entry.description}`);
  }
  return {
    contents: { kind: MarkupKind.Markdown, value: lines.join('\n\n') },
    range: { start: document.positionAt(token.start), end: document.positionAt(token.end) },
  };
});

connection.onCodeAction(({ textDocument, context }) =>
  context.diagnostics
    .filter((diagnostic) => diagnostic.source === 'swiftcn' && diagnostic.data?.suggestion)
    .map((diagnostic) => ({
      title: `Replace with '${diagnostic.data.suggestion}'`,
      kind: CodeActionKind.QuickFix,
      diagnostics: [diagnostic],
      isPreferred: true,
      edit: { changes: { [textDocument.uri]: [{ range: diagnostic.range, newText: diagnostic.data.suggestion }] } },
    })));

documents.listen(connection);
connection.listen();
