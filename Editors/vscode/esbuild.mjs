// Bundles the extension and the language server, with their dependencies, into dist/.
import { build, context } from 'esbuild';

const common = { bundle: true, platform: 'node', format: 'cjs', target: 'node18', logLevel: 'warning' };
const builds = [
  { ...common, entryPoints: ['src/extension.ts'], outfile: 'dist/extension.cjs', external: ['vscode'] },
  { ...common, entryPoints: ['src/server.ts'], outfile: 'dist/server.cjs' },
];

if (process.argv.includes('--watch')) {
  for (const options of builds) await (await context(options)).watch();
} else {
  await Promise.all(builds.map((options) => build(options)));
}
