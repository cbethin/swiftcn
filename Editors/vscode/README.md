# swiftcn for VS Code and Cursor

Completions, hover docs, and typo fixes for [swiftcn](https://github.com/cbethin/swiftcn) classes in SwiftUI code.
It works in VS Code, Cursor, Windsurf, VSCodium, and any editor that speaks the Language Server Protocol.

- **Completions** inside `.tw("…")`, `.buttonStyle(.tw("…"))`, `cn(…)`, `classes:` arguments, and `TWClasses` literals: every class, variant, and bracket value, with what each one does.
- **Hover** a class to see what it maps to, such as `text-lg`: *Font .title3. Scales with Dynamic Type.*
- **Warnings** for unknown classes, with a quick fix for the closest valid one: `bg-surfce` → `bg-surface`.
- **Your own names**: recipes, modifiers, utilities, animations, and `TWColor` colors that your project registers are suggested and never reported.

The class list is generated from swiftcn's parser, so suggestions match what swiftcn accepts at run time.
It runs alongside the Swift extension; inside class strings it adds the suggestions that SourceKit-LSP cannot.

## Settings

| Setting | Default | |
| --- | --- | --- |
| `swiftcn.diagnostics.severity` | `warning` | `warning`, `error`, or `off` |

Suppress one line with `// swiftcn-lint: ignore`, or the next line with `// swiftcn-lint: ignore-next-line`.

For errors at build time, in Xcode and CI too, add swiftcn's `SwiftCNLintPlugin` build plugin. See [build-time checks](https://cbethin.github.io/swiftcn/docs/build-time-checks/).

## Other editors

The extension bundles `swiftcn-language-server`, a standard LSP server over stdio. Install it from a swiftcn checkout:

```sh
cd Editors/vscode && npm ci && npm run build && npm link
```

Neovim 0.11:

```lua
vim.lsp.config('swiftcn', {
  cmd = { 'swiftcn-language-server', '--stdio' },
  filetypes = { 'swift' },
  root_markers = { 'Package.swift', '.git' },
})
vim.lsp.enable('swiftcn')
```

Helix (`languages.toml`):

```toml
[language-server.swiftcn]
command = "swiftcn-language-server"
args = ["--stdio"]

[[language]]
name = "swift"
language-servers = ["sourcekit-lsp", "swiftcn"]
```

Sublime Text (LSP package) and Emacs (Eglot) run it the same way: `swiftcn-language-server --stdio` for Swift files.

## Development

```sh
npm ci
npm test        # builds, then runs unit tests and Language Server Protocol tests
npm run package # creates swiftcn-<version>.vsix
```

Regenerate the class list after changing swiftcn's parser:

```sh
swift run swiftcn-lint --catalog-json > Editors/vscode/data/classes.json
```
